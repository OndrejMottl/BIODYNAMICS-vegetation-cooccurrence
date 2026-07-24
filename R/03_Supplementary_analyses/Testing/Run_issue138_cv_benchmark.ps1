param(
  [Parameter(Mandatory = $true)]
  [string]$RunnerPath,

  [Parameter(Mandatory = $true)]
  [ValidateSet("exhaustive", "staged")]
  [string]$TuningStrategy,

  [Parameter(Mandatory = $true)]
  [ValidateRange(1, 1000)]
  [int]$RepetitionId,

  [Parameter(Mandatory = $true)]
  [string]$TargetStore,

  [string]$VegVaultSha256 = "",

  [ValidateRange(1, 60)]
  [int]$SampleIntervalSeconds = 1
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path(
  Join-Path $PSScriptRoot "../../.."
)
$runnerAbsolute = Resolve-Path(
  Join-Path $repositoryRoot $RunnerPath
)
$targetStoreAbsolute = Join-Path $repositoryRoot $TargetStore
$resultDirectory = Join-Path `
  $repositoryRoot `
  "Data/Temp/issue138/$TuningStrategy/repetition_$RepetitionId"

if (Test-Path -LiteralPath $resultDirectory) {
  throw "Benchmark result directory already exists: $resultDirectory"
}

New-Item -ItemType Directory -Path $resultDirectory | Out-Null

$stdoutPath = Join-Path $resultDirectory "stdout.log"
$stderrPath = Join-Path $resultDirectory "stderr.log"
$samplePath = Join-Path $resultDirectory "resource_samples.csv"
$metadataPath = Join-Path $resultDirectory "environment.json"
$summaryPath = Join-Path $resultDirectory "run_summary.json"
$harnessErrorPath = Join-Path $resultDirectory "harness_error.txt"
$samplingWarningPath = Join-Path $resultDirectory "sampling_warnings.log"
$rscriptPath = (Get-Command Rscript).Source

$vegvaultPath = Join-Path $repositoryRoot "Data/Input/VegVault.sqlite"
$vegvaultExists = Test-Path -LiteralPath $vegvaultPath

if ($VegVaultSha256 -ne "" -and $VegVaultSha256 -notmatch "^[A-Fa-f0-9]{64}$") {
  throw "VegVaultSha256 must be empty or a 64-character hexadecimal hash."
}

$vegvaultHash = if (-not $vegvaultExists) {
  $null
} elseif ($VegVaultSha256 -ne "") {
  $VegVaultSha256.ToUpperInvariant()
} else {
  (Get-FileHash -LiteralPath $vegvaultPath -Algorithm SHA256).Hash
}

$gpuEnvironment = & nvidia-smi `
  --query-gpu=name,driver_version,memory.total,memory.free `
  --format=csv,noheader,nounits

$memoryEnvironment = Get-CimInstance Win32_OperatingSystem

$metadata = [ordered]@{
  recorded_at = (Get-Date).ToString("o")
  git_commit = (& git -C $repositoryRoot rev-parse HEAD).Trim()
  renv_lock_sha256 = (
    Get-FileHash -LiteralPath (Join-Path $repositoryRoot "renv.lock") `
      -Algorithm SHA256
  ).Hash
  config_sha256 = (
    Get-FileHash -LiteralPath (Join-Path $repositoryRoot "config.yml") `
      -Algorithm SHA256
  ).Hash
  runner_path = $RunnerPath
  runner_sha256 = (
    Get-FileHash -LiteralPath $runnerAbsolute -Algorithm SHA256
  ).Hash
  tuning_strategy = $TuningStrategy
  repetition_id = $RepetitionId
  target_store = $TargetStore
  rscript_path = $rscriptPath
  gpu_environment = $gpuEnvironment
  total_visible_memory_kib = $memoryEnvironment.TotalVisibleMemorySize
  free_physical_memory_kib = $memoryEnvironment.FreePhysicalMemory
  vegvault_path = if (-not $vegvaultExists) {
    $null
  } else {
    $vegvaultPath
  }
  vegvault_bytes = if (-not $vegvaultExists) {
    $null
  } else {
    (Get-Item -LiteralPath $vegvaultPath).Length
  }
  vegvault_modified_at = if (-not $vegvaultExists) {
    $null
  } else {
    (Get-Item -LiteralPath $vegvaultPath).LastWriteTime.ToString("o")
  }
  vegvault_sha256 = if (-not $vegvaultExists) {
    $null
  } else {
    $vegvaultHash
  }
}

$metadata |
  ConvertTo-Json -Depth 4 |
  Set-Content -LiteralPath $metadataPath -Encoding utf8

function Get-DescendantProcessIds {
  param([int]$RootProcessId)

  $allProcesses = Get-CimInstance Win32_Process
  $selectedIds = [System.Collections.Generic.List[int]]::new()
  $selectedIds.Add($RootProcessId)
  $searchIndex = 0

  while ($searchIndex -lt $selectedIds.Count) {
    $parentId = $selectedIds[$searchIndex]
    $childIds = $allProcesses |
      Where-Object { $_.ParentProcessId -eq $parentId } |
      Select-Object -ExpandProperty ProcessId

    foreach ($childId in $childIds) {
      if (-not $selectedIds.Contains([int]$childId)) {
        $selectedIds.Add([int]$childId)
      }
    }

    $searchIndex += 1
  }

  return $selectedIds
}

function Convert-GpuMetric {
  param([string]$Value)

  if ($Value -match "^-?[0-9]+([.][0-9]+)?$") {
    return [double]::Parse(
      $Value,
      [Globalization.CultureInfo]::InvariantCulture
    )
  }

  return [double]::NaN
}

$process = Start-Process `
  -FilePath $rscriptPath `
  -ArgumentList @($runnerAbsolute) `
  -WorkingDirectory $repositoryRoot `
  -RedirectStandardOutput $stdoutPath `
  -RedirectStandardError $stderrPath `
  -WindowStyle Hidden `
  -PassThru

$startedAt = Get-Date
$peakWorkingSetBytes = 0L
$peakSystemUsedBytes = 0L
$peakVramMib = 0.0
$gpuMemoryFailure = $false
$sampleHeaderWritten = $false
$maximumConsecutiveSamplingFailures = 30
$consecutiveSamplingFailures = 0
$lastKnownProcessIds = @($process.Id)

try {
  while (-not $process.HasExited) {
    try {
      $sampledAt = Get-Date
      $processIds = Get-DescendantProcessIds -RootProcessId $process.Id
      $lastKnownProcessIds = @($processIds)
      $processes = Get-Process -Id $processIds -ErrorAction SilentlyContinue
      $workingSetBytes = ($processes | Measure-Object WorkingSet64 -Sum).Sum

      if ($null -eq $workingSetBytes) {
        $workingSetBytes = 0L
      }

      $systemMemory = Get-CimInstance Win32_OperatingSystem
      $systemUsedBytes = (
        $systemMemory.TotalVisibleMemorySize -
          $systemMemory.FreePhysicalMemory
      ) * 1KB

      $gpuSampleRaw = & nvidia-smi `
        --query-gpu=utilization.gpu,memory.used,temperature.gpu,power.draw `
        --format=csv,noheader,nounits
      $gpuValues = $gpuSampleRaw -split "," |
        ForEach-Object { $_.Trim() }

      $gpuUtilization = Convert-GpuMetric $gpuValues[0]
      $vramUsedMib = Convert-GpuMetric $gpuValues[1]
      $gpuTemperature = Convert-GpuMetric $gpuValues[2]
      $gpuPowerWatts = Convert-GpuMetric $gpuValues[3]

      $peakWorkingSetBytes = [Math]::Max(
        $peakWorkingSetBytes,
        $workingSetBytes
      )
      $peakSystemUsedBytes = [Math]::Max(
        $peakSystemUsedBytes,
        $systemUsedBytes
      )
      if (-not [double]::IsNaN($vramUsedMib)) {
        $peakVramMib = [Math]::Max($peakVramMib, $vramUsedMib)
      }

      $sample = [pscustomobject]@{
        sampled_at = $sampledAt.ToString("o")
        elapsed_seconds = ($sampledAt - $startedAt).TotalSeconds
        process_count = $processes.Count
        process_working_set_bytes = $workingSetBytes
        system_used_memory_bytes = $systemUsedBytes
        gpu_utilization_percent = $gpuUtilization
        vram_used_mib = $vramUsedMib
        gpu_temperature_celsius = $gpuTemperature
        gpu_power_watts = $gpuPowerWatts
      }

      if ($sampleHeaderWritten) {
        $sample |
          Export-Csv -LiteralPath $samplePath -NoTypeInformation -Append
      } else {
        $sample | Export-Csv -LiteralPath $samplePath -NoTypeInformation
        $sampleHeaderWritten = $true
      }

      $consecutiveSamplingFailures = 0
    } catch {
      $consecutiveSamplingFailures += 1
      $samplingWarning = [ordered]@{
        sampled_at = (Get-Date).ToString("o")
        consecutive_failures = $consecutiveSamplingFailures
        message = $_.Exception.Message
      }
      $samplingWarning |
        ConvertTo-Json -Compress |
        Add-Content -LiteralPath $samplingWarningPath -Encoding utf8

      if (
        $consecutiveSamplingFailures -ge
          $maximumConsecutiveSamplingFailures
      ) {
        throw
      }
    }

    Start-Sleep -Seconds $SampleIntervalSeconds
    $process.Refresh()
  }
} catch {
  $_ | Out-String | Set-Content -LiteralPath $harnessErrorPath -Encoding utf8
  Stop-Process -Id $lastKnownProcessIds -Force -ErrorAction SilentlyContinue
  throw
}

$process.WaitForExit()
$endedAt = Get-Date

$storeBytes = if (Test-Path -LiteralPath $targetStoreAbsolute) {
  (
    Get-ChildItem -LiteralPath $targetStoreAbsolute -Recurse -File |
      Measure-Object Length -Sum
  ).Sum
} else {
  0L
}

$stderrText = if (Test-Path -LiteralPath $stderrPath) {
  Get-Content -LiteralPath $stderrPath -Raw
} else {
  ""
}
$gpuMemoryFailure = [bool](
  $stderrText -match "CUDA out of memory|out of memory|CUDA error"
)

$summary = [ordered]@{
  tuning_strategy = $TuningStrategy
  repetition_id = $RepetitionId
  started_at = $startedAt.ToString("o")
  ended_at = $endedAt.ToString("o")
  wall_seconds = ($endedAt - $startedAt).TotalSeconds
  exit_code = $process.ExitCode
  peak_process_working_set_bytes = $peakWorkingSetBytes
  peak_system_used_memory_bytes = $peakSystemUsedBytes
  peak_vram_mib = $peakVramMib
  gpu_memory_failure = $gpuMemoryFailure
  target_store_bytes = $storeBytes
  resource_sample_path = $samplePath
  stdout_path = $stdoutPath
  stderr_path = $stderrPath
}

$summary |
  ConvertTo-Json -Depth 4 |
  Set-Content -LiteralPath $summaryPath -Encoding utf8

if ($process.ExitCode -ne 0) {
  throw "Benchmark runner exited with code $($process.ExitCode)."
}

$summary | ConvertTo-Json -Depth 4

# Benchmark gate infrastructure: preliminary validation v1

Date: 2026-07-20  
Branch: `issue138-cv-runtime`

## Implemented infrastructure

The shared `assess_sjsdm_staged_benchmark()` evaluator converts three paired
exhaustive/staged repetitions into criterion-level evidence and one versioned
decision. It enforces the frozen wall-time, fit-count, storage, RAM/VRAM,
GPU-failure, technical-status, assignment, artifact-schema, log-loss, AUC,
Tjur R2, and evaluable-coverage gates. A changed selected candidate produces a
mandatory `scientific_review` result even when all numeric gates pass.

`Run_issue138_cv_benchmark.ps1` launches any supplied pipeline runner in an
isolated process and records:

- commit, configuration, runner, `renv.lock`, and VegVault hashes;
- one-second process-tree working set and system-memory samples;
- one-second GPU utilization, VRAM, temperature, and available power samples;
- complete stdout and stderr logs;
- wall time, exit status, GPU-memory-failure detection, and store size; and
- environment and summary JSON files beside the raw CSV samples.

Unsupported NVIDIA fields are stored as missing values. The sampler refuses to
overwrite an existing repetition directory. A previously verified VegVault
hash may be supplied to avoid repeatedly hashing the unchanged large SQLite
file immediately before paired runs.

## First staged attempt

The first measured staged attempt is retained under ignored
`Data/Temp/issue138/` evidence but is not a valid benchmark repetition. It
completed all 40 round-one candidate/fold fits and then failed closed at the
first tier aggregation. The failure exposed a shared collector assumption:
resolution summaries were assumed to have suffixed target names, whereas the
existing paleo-core public target is the unsuffixed
`data_sjsdm_tuning_summary`.

The generic collector now accepts an optional explicit target-name mapping.
The tier pipeline uses this mapping for the direct paleo-core unit while all
existing spatial and temporal suffixed targets retain their previous behavior.
No public target was renamed and no CZ-specific selection logic was added.

Diagnostic resource evidence from the invalid attempt was:

| Measurement | Observed value |
|---|---:|
| Wall time to fail-closed boundary | 670.8 seconds |
| Resource samples | 422 |
| Completed round-one fits | 40 |
| Peak process-tree working set | 8.365 GiB |
| Peak system memory used | 26.497 GiB |
| Peak VRAM | 1,603 MiB |
| Peak sampled GPU utilization | 67% |
| GPU memory failure | No |

These values are diagnostic only and must not enter paired gate calculations.

## Validation

- Focused collector and tier-pipeline contracts passed with 21 assertions.
- The benchmark evaluator passed 11 focused assertions, including failure and
  scientific-review outcomes.
- The complete suite passed with 3,771 assertions, zero failures, zero
  warnings, and one expected integration skip.
- Fresh `run_cz_pipelines.R` completed in 1,889.1 seconds with exit code 0.
- Fresh target metadata contained 552 paleo-core, 692 paleo-resolution, and
  2,490 modern-resolution rows, with zero errors in every store.
- Changed R files parse, remain within 80 characters, and the PowerShell
  sampler passes parser validation.

Production remains exhaustive. Clean staged and exhaustive repetitions must be
rerun after this collector fix is committed; only those runs may enter the
paired gate evaluator.

The later version-two runtime policy is recorded in
[`benchmark_policy_revision_v2.md`](benchmark_policy_revision_v2.md). The
original validation above remains evidence for the version-one evaluator.

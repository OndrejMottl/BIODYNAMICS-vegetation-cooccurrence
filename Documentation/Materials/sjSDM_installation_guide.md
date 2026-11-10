# sjSDM Setup: R, Python and VS Code

`{sjSDM}` is an R package that fits its models in Python with PyTorch, called through `{reticulate}`. This guide sets up that Python side for this project and connects it to R in VS Code, RStudio, `Rscript` and `{targets}` workers.

It assumes the general R setup described in [VS Code for R](https://ondrejmottl.github.io/collaboration/vscode_r_setup/): R versions managed by [rig](https://github.com/r-lib/rig), radian as the R console, Python 3.12 first on `PATH`, and no machine-specific paths in synced settings. Only the parts specific to this project are covered here.

## Why this project needs special settings

radian is a Python program that embeds R. When R runs inside radian, the R process already contains radian's Python, and reticulate must use that same Python, because one process cannot load two. `RETICULATE_PYTHON` cannot change this.

So the global radian (system Python 3.12, no PyTorch) cannot run `{sjSDM}`. This project therefore uses a dedicated Python environment that holds both PyTorch and its own radian:

- In VS Code, the workspace starts radian from that environment, so radian's Python is the one with PyTorch.
- Everywhere else (`Rscript`, `{targets}` and callr workers, RStudio) R is not inside radian, and the project `.Renviron` points reticulate at the same environment through `RETICULATE_PYTHON`.

Without either setting, reticulate 1.46 quietly creates a throwaway Python without PyTorch, and `{sjSDM}` reports `torch`, `torch_optimizer`, `pyro` and `madgrad` as missing.

## The pinned stack

| Component | Version | Where it is recorded |
|---|---|---|
| R | 4.5.1 | `renv.lock` |
| `{sjSDM}`, `{reticulate}` | see lockfile | `renv.lock` |
| Python | 3.12 | uv virtual environment `%LOCALAPPDATA%\r-sjsdm` |
| PyTorch | 2.5.1+cu121 | pinned at install, see below |
| pyro-ppl, torch_optimizer, madgrad, numpy, radian | latest at install | `pip freeze` of the environment |

Last verified on 2026-11-09 (Windows 11, NVIDIA GeForce RTX 3050): R 4.5.1, Python 3.12.10, PyTorch 2.5.1+cu121, numpy 2.5.4, pyro-ppl 1.9.2, torch_optimizer 0.3.0, madgrad 1.3, radian 0.8.0, with all `diagnose_sjsdm_setup(run_test_model = TRUE)` checks passing.

PyTorch stays on 2.5.1, the version that produced the current calibrated results. Change it only as a deliberate, documented step, because a different PyTorch can change fitted values.

## Setup on Windows

### 1. R version

Install R 4.5.1 with rig and create the version-named links (`R-4.5.1.exe`) once per machine:

```powershell
rig add 4.5.1
rig system make-links
```

Then restore the package library from the repository root:

```powershell
rig run -r 4.5.1 -e "renv::restore()"
```

### 2. Python environment

Create the environment with [uv](https://docs.astral.sh/uv/) outside the repository, so every worktree shares it. The CUDA build needs an NVIDIA GPU; on a machine without one, replace `cu121` by `cpu` in both places.

```powershell
uv venv --python 3.12 "$env:LOCALAPPDATA\r-sjsdm"
uv pip install --python "$env:LOCALAPPDATA\r-sjsdm\Scripts\python.exe" `
  "torch==2.5.1+cu121" numpy pyro-ppl torch_optimizer madgrad radian `
  --extra-index-url https://download.pytorch.org/whl/cu121 `
  --index-strategy unsafe-best-match
```

Check it:

```powershell
& "$env:LOCALAPPDATA\r-sjsdm\Scripts\python.exe" -c "import torch, pyro, torch_optimizer, madgrad; print(torch.__version__, torch.cuda.is_available())"
```

This should print `2.5.1+cu121 True`.

Do not use `sjSDM::install_sjSDM()`. It installs Miniconda and a separate conda environment, which this setup replaces.

### 3. Project `.Renviron`

Create `.Renviron` in the repository root. It is git-ignored, so it is machine-local. Use the full path with forward slashes: R strips backslashes when it expands variables such as `${LOCALAPPDATA}` in this file.

```text
RETICULATE_PYTHON=C:/Users/<user>/AppData/Local/r-sjsdm/Scripts/python.exe
```

### 4. VS Code workspace settings

Pin the R version with the [R Version Switcher](https://github.com/OndrejMottl/r-version-switcher) command **R: Use R Version from renv.lock**. It writes `r.executablePath` and `r.consoleArgs` (with `--r-binary=R-4.5.1.exe`) to `.vscode/settings.json`, and keeps `r.rpath.windows` when the R Debugger extension is installed.

Then add the radian from the Python environment by hand, as the switcher does not set the console:

```json
"r.consolePath": "${userHome}/AppData/Local/r-sjsdm/Scripts/radian.exe"
```

The resulting `.vscode/settings.json` (git-ignored) looks like this:

```json
{
  "r.executablePath": "R-4.5.1.exe",
  "r.consoleArgs": ["--no-save", "--no-restore", "--r-binary=R-4.5.1.exe"],
  "r.rpath.windows": "R-4.5.1.exe",
  "r.consolePath": "${userHome}/AppData/Local/r-sjsdm/Scripts/radian.exe"
}
```

Quit all VS Code windows and start it again, since a window reload does not refresh the console settings or `PATH`.

### 5. Verify

In a new R terminal in VS Code, and once with `rig run -r 4.5.1` from the repository root:

```r
R.version.string            # R 4.5.1
reticulate::py_config()     # python: ...\r-sjsdm\Scripts\python.exe

source("R/___setup_project___.R")
diagnose_sjsdm_setup()
```

All checks should report `[OK]`, with CUDA available on a GPU machine.

## Running scripts outside VS Code

The machine's default R may be a newer version whose renv library is empty. Run project scripts with the pinned version from the repository root:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/Testing/Run_tests.R
```

Quarto chooses R independently of rig, so set `QUARTO_R` to the pinned R's `bin` folder before rendering, for example `$env:QUARTO_R = "C:/Program Files/R/R-4.5.1/bin"`.

## Git worktrees

`.Renviron` and `.vscode/settings.json` are git-ignored, so a new worktree starts without them. Copy both from the main worktree (see `.ai/git-workflow.md`). Without `.Renviron`, `{sjSDM}` falls back to a throwaway Python without PyTorch. The Python environment itself is shared and needs no copy.

## Linux and HPC

The same environment works without radian. Create a venv with `uv venv --python 3.12 ~/.venvs/r-sjsdm`, install the same packages (use the PyTorch index that matches the cluster's CUDA version), skip radian, and set `RETICULATE_PYTHON=~/.venvs/r-sjsdm/bin/python` in the project `.Renviron`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `torch`, `pyro`, `torch_optimizer`, `madgrad` reported missing when `{sjSDM}` loads | reticulate is not using the `r-sjsdm` environment | Check `reticulate::py_config()`. Outside radian, check `Sys.getenv("RETICULATE_PYTHON")` and that the file exists. In VS Code, check that `r.consolePath` points at the environment's radian. |
| `py_config()` shows the system Python 3.12 in VS Code | The global radian started, not the environment's | Check `r.consolePath` in `.vscode/settings.json`, then fully restart VS Code |
| `there is no package called 'dplyr'` or similar at start-up | The default R (for example 4.6) started instead of 4.5.1 | Use `rig run -r 4.5.1`, or check the switcher status bar item and `r.consoleArgs` in VS Code |
| `RETICULATE_PYTHON` looks like `C:UsersAppData...` | `${LOCALAPPDATA}` or backslashes in `.Renviron` | Write the full path with forward slashes |
| CUDA not available | CPU build of PyTorch installed, or outdated NVIDIA driver | Check `torch.__version__` ends in `+cu121` and `nvidia-smi` works; reinstall PyTorch from the CUDA index |
| radian does not start | Python or rchitect mismatch in the environment | Run `& "$env:LOCALAPPDATA\r-sjsdm\Scripts\radian.exe" --r-binary=R-4.5.1.exe --version`; reinstall radian into the environment |

For a deeper look, run `diagnose_sjsdm_gpu_runtime(verbose = TRUE)` and `sjSDM::install_diagnostic()`.

## References

- [sjSDM on CRAN](https://cran.r-project.org/package=sjSDM) and its [installation help](https://cran.r-project.org/web/packages/sjSDM/vignettes/Installation_help.html)
- [reticulate: Python version configuration](https://rstudio.github.io/reticulate/articles/versions.html)
- [radian](https://github.com/randy3k/radian)
- [PyTorch installation](https://pytorch.org/get-started/locally/)

# Modern spatial convergence sensitivity

## Purpose and backstory

This workflow summarises modern spatial convergence, optionally saves plot
grids, and can rerun non-converged units after model-tuning review. It was
moved out of the main-analysis tree under issue #152 because it is an
operator-controlled sensitivity study rather than a stable production
analysis.

## Status and entry point

Status: active, operator-controlled sensitivity workflow.

Supported entry point:
`tune_modern_spatial_convergence.R`.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Sensitivity/Modelling/Spatial/Modern/tune_modern_spatial_convergence.R
```

## Prerequisites and configuration

Project dependencies and completed modern spatial stores must be available.
Review `flag_save_plot_grids` and `flag_rerun_non_converged` at the start of
the script. Both default to `FALSE`. Review diagnostics before changing
`Data/Input/Model_tuning/*.csv` or enabling reruns.

## Outputs and interpretation

The script prints status and convergence summaries. When explicitly enabled,
it writes plot grids under `Outputs/Figures/Model_tuning` and reruns affected
target stores. Convergence improvement alone does not establish better
scientific performance; tuning changes require their own evidence.

## Regeneration and retirement

Run after fitting changes or when modern model convergence needs investigation.
Do not enable reruns or plot writes in unattended validation. Retire when the
fitting workflow provides an accepted automated convergence policy and
maintained reporting. Related work: issue #152 and issue #149.

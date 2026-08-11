# Paleo spatial convergence recovery

## Purpose and backstory

This operator-assisted workflow identifies non-converged paleo spatial models, shows the relevant tuning evidence, and can rerun affected units after the tuning tables are reviewed. It was moved out of the main-analysis tree under issue #152 because it is a sensitivity and recovery workflow, not a routine production runner.

## Status and entry point

Status: active, operator-controlled sensitivity workflow.

Supported entry point: `rerun_non_converged_spatial_models.R`.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Sensitivity/Modelling/Spatial/Paleo/rerun_non_converged_spatial_models.R
```

## Prerequisites and configuration

Project dependencies, `Data/Input/spatial_grid.csv`, and the existing paleo spatial target stores must be available. First run only the diagnostic sections, review their output, and make any scientifically justified changes to `Data/Input/Model_tuning/*.csv`. The rerun section changes target stores and must be run only after that review.

## Outputs and interpretation

The diagnostic sections print convergence and tuning summaries. The rerun section executes affected spatial pipelines in their existing stores. A successful rerun shows operational completion; acceptance of a tuning change still requires review of convergence and scientific performance.

## Regeneration and retirement

Use only when production stores contain non-converged model units. Do not run as a routine blanket refresh. Retire when model fitting no longer requires manual tuning recovery or when a supported automated recovery policy replaces it. Record material tuning decisions separately. Related work: issue #152 and issue #149.

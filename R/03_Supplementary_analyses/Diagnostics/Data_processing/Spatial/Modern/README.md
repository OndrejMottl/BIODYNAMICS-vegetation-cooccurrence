# Modern spatial preprocessing diagnostics

## Purpose and backstory

This workflow inspects extraction, coordinate quality, deduplication, and
cross-database aggregation for one modern continental spatial unit. It was
moved out of the main-analysis tree under issue #152 because it is a targeted
data-processing diagnostic.

## Status and entry point

Status: active diagnostic.

Supported entry point:
`diagnose_modern_preprocessing.R`.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Diagnostics/Data_processing/Spatial/Modern/diagnose_modern_preprocessing.R
```

## Prerequisites and configuration

Project dependencies, `Data/Input/spatial_grid.csv`, and the configured modern
data sources must be available. Set `R_CONFIG_ACTIVE` before running to inspect
a different selectable modern spatial profile; otherwise the script uses
`project_modern_spatial_continental`. Review the selected spatial unit near the
start of the script before execution.

## Outputs and interpretation

The script builds the required preprocessing targets in the selected target
store and prints quality-control and aggregation tables. It does not produce a
final scientific result. Findings apply only to the selected profile and
spatial unit and should not be extrapolated to all modern inputs without a
representative check.

## Regeneration and retirement

Run when modern preprocessing changes or when duplicate and coordinate
behaviour needs investigation. Retire only after equivalent checks are part of
a maintained validation target or report. Related work: issue #152 and issue
#149.

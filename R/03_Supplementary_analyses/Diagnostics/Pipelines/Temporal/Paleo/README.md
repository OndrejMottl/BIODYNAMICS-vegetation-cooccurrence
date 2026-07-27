# Paleo temporal pipeline diagnostics

## Purpose and backstory

This diagnostic compares target status, convergence, and fitted-model R2
across the continental paleo temporal pipelines. It was separated from the
main-analysis tree under issue #152 because it explains pipeline behaviour
rather than creating a primary output.

## Status and entry point

Status: active diagnostic.

Supported entry point:
`diagnose_temporal_continents.R`.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Diagnostics/Pipelines/Temporal/Paleo/diagnose_temporal_continents.R
```

## Prerequisites and configuration

Project dependencies and `Data/Input/spatial_grid.csv` must be available. Run
the supported temporal production runners first so the corresponding
`Data/targets/project_paleo_temporal_<continent>/pipeline_paleo_temporal`
stores exist. The script derives the continental profile IDs from the spatial
grid and switches among those profiles during execution.

## Outputs and interpretation

The workflow prints per-continent status, convergence, and R2 summaries and
creates convergence plot grids in the active R graphics device. It does not
write a canonical report or mutate stores. Comparisons are descriptive and do
not replace out-of-sample model evaluation.

## Regeneration and retirement

Run after temporal production batches or when investigating a continental
store. Retire only after a maintained multi-continent diagnostic provides the
same evidence. Related work: issue #152 and issue #149.

# Paleo spatial pipeline diagnostics

## Purpose and backstory

This diagnostic consolidates status, errors, convergence, and fitted-model evaluation across the continental, regional, and local paleo spatial target stores. It was moved out of the main-analysis tree under issue #152 because it explains pipeline health rather than producing a primary scientific result.

## Status and entry point

Status: active diagnostic.

Supported entry point: `diagnose_spatial_pipelines.R`.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Diagnostics/Pipelines/Spatial/Paleo/diagnose_spatial_pipelines.R
```

## Prerequisites and configuration

Project dependencies must be restored. `Data/Input/spatial_grid.csv` must be present. The script reads any available stores below `Data/targets/paleo_spatial_<scale>/<scale_id>/pipeline_paleo_spatial_resolution` and tolerates missing or incomplete stores.

## Outputs and interpretation

The script prints pipeline-status, error-lineage, convergence, and evaluation tables and creates interactive convergence plot grids. It does not write a canonical report or change target stores. Missing targets and non-convergence are diagnostic findings, not by themselves evidence that the scientific results are invalid.

## Regeneration and retirement

Run after spatial production batches or when investigating failures. Keep this workflow active while the three spatial-scale pipelines use separate stores. Retire it only when an equivalent maintained status report replaces it and the replacement is documented. Related work: issue #152 and the architecture refactor in issue #149.

# Spatial-grid scientific reference

## Purpose and backstory

This folder owns the guarded generator for `Data/Input/spatial_grid.csv`, the catalogue of continental, regional, and local spatial units used throughout the project. The generator previously lived under `R/01_Data_processing`, where its reference-building role and overwrite risk were not explicit.

## Status and entry point

Status: active guarded scientific-reference generator.

`build_spatial_grid_catalogue.R` constructs the catalogue from the documented continental bounds. It aborts by default. A maintainer must review the script and deliberately set `flag_allow_overwrite <- TRUE` before it can replace the tracked input.

Run from the repository root only after that review:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Scientific_references/Spatial_grid/build_spatial_grid_catalogue.R
```

## Prerequisites and configuration

Run from the repository root after reviewing the continental bounds and the overwrite guard. No production profile should silently regenerate this file.

## Outputs and interpretation

The script writes `Data/Input/spatial_grid.csv`. Changing its geometries or `scale_id` values affects target stores, tuning records, and downstream model outputs. Model-fitting parameters remain separately owned by `Data/Input/Model_tuning/`.

## Regeneration and retirement

Regenerate only for an approved spatial-catalogue migration and review the CSV diff before invalidating downstream stores. Keep this workflow while the project derives spatial units from the tracked catalogue.

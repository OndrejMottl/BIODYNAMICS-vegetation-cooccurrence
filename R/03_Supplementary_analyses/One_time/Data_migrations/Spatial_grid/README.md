# Spatial-grid data migrations

## Purpose and backstory

This folder records completed one-time migrations of the tracked spatial-grid catalogue. The current script added resolution-specific model-parameter columns before those parameters were separated from the geometry catalogue. It previously remained in an `_outdated` production-data folder without an explicit lifecycle contract.

## Status and entry point

`migrate_spatial_grid_resolution_columns.R` is retained as provenance. It was designed to modify `Data/Input/spatial_grid.csv` in place and abort when the migration had already been applied.

Do not run it during normal maintenance. The current catalogue already contains the migration outcome, and model-tuning parameters now live under `Data/Input/Model_tuning/`.

## Prerequisites and configuration

No normal configuration profile applies. Reproduction requires the historical pre-migration `Data/Input/spatial_grid.csv` and explicit maintainer review.

## Outputs and interpretation

The historical output was an updated `Data/Input/spatial_grid.csv`. The script does not represent the current catalogue-regeneration workflow; use the scientific-reference spatial-grid README for that workflow.

## Regeneration and retirement

Keep the script as migration provenance while historical spatial-grid changes need to remain auditable. It may be removed only after confirming that no release or reproducibility record depends on reconstructing this migration.

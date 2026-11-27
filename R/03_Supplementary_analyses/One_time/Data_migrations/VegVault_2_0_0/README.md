# VegVault 2.0.0 release comparison

## Purpose and backstory

The project moved from VegVault 1.0.0 to VegVault 2.0.0 before the full rebuild of its models (`Documentation/Implementation_plans/2026-11-25_vegvault_2_migration_plan.md`, step V5). Version 2.0.0 is a major release: a fresh Neotoma download of fossil pollen, merged plot taxa, trait units standardised at the source, TRY coordinates outside the valid range set to missing, and corrected present-day temperature seasonality (`bio4`). These scripts compare the two files for the project's continental windows, so that the change of input data is documented before any model is refitted. Their results replace the release checks planned for the start of the rebuild.

## Status and entry point

Status: one-time provenance of the migration. Both scripts only read the two database files.

Entry points, run from the repository root with the pinned R version:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/One_time/Data_migrations/VegVault_2_0_0/compare_vegvault_release_records.R
rig run -r 4.5.1 R/03_Supplementary_analyses/One_time/Data_migrations/VegVault_2_0_0/compare_vegvault_release_climate.R
```

## Prerequisites and configuration

- `Data/Input/VegVault.sqlite` (2.0.0) and `Data/Input/VegVault_1.0.0.sqlite`, opened read-only. The 1.0.0 file is kept until the rebuild is finished.
- The continental rows of `Data/Input/spatial_grid.csv`. The temporal profiles use the same three windows.
- The extraction settings of `project_paleo_spatial_continental` (fossil pollen, 0 to 20,000 cal yr BP, and the climate variables) and `project_modern_spatial_continental` (vegetation plots at 0 cal yr BP).

## Outputs and interpretation

All outputs go to `Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/`; its README interprets them.

- `compare_vegvault_release_records.R`:
  - `release_window_counts.csv`: datasets, samples and taxa per continent, data type and release. Records without a value (presence-only plot records) are counted separately, because `vaultkeepr::extract_data()` drops them and they never reach the pipelines.
  - `release_trait_sources.csv`: trait datasets, values and taxa per continent and source type (TRY, BIEN), and trait datasets without coordinates.
  - `release_fossil_cores_at_0_ka.csv`: fossil-pollen cores with a sample at 0 cal yr BP. Extraction keeps ages from 0 and the age interpolation does not extrapolate, so only these cores give a sample at the 0 ka slice of the temporal models.
  - `release_window_counts.png`: the counts that reach the pipelines, for co-author material.
- `compare_vegvault_release_climate.R`:
  - `release_climate_by_age.csv`: per continent, climate variable and age, the gridpoints, missing values, zeros and values that differ between the releases, matched by sample name.
  - `release_climate_checks.csv`: per continent, the checks of the release notes: `bio4` at 0 ka (zeros, minimum, ratio to 500 cal yr BP), values that differ other than `bio4` at 0 ka, missing values, `bio12` at its storage limit, and zeros of `bio18` and `bio19`.

The counts use direct SQL with the windows and age ranges of the pipelines, not the pipelines themselves; deduplication and later filters of the pipelines are not applied.

## Regeneration and retirement

Rerun only if either database file changes. Retire with the 1.0.0 file, after the rebuild on 2.0.0 is finished and published.

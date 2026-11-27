# Taxon classification coverage

## Purpose and backstory

The community and trait pipelines classify every taxon name of their VegVault extraction with taxospace (cache in `Data/Temp/taxospace`) and with `Data/Input/aux_classification_table.csv`, which takes precedence. A name that neither covers stops `validate_taxa_classification_coverage()` and the trait classification check, after the pipeline has appended it to `Data/Input/missing_taxa_template.csv`. This diagnostic finds such names before a pipeline run, for every continental window and data type at once. It was written for step V4 of the VegVault 2.0.0 migration (`Documentation/Implementation_plans/2026-11-25_vegvault_2_migration_plan.md`).

It also covers the combined pollen types of VegVault 2.0.0, such as "Larix Pseudotsuga". VegVault 2.0.0 places each of them at the family the genera share, with no genus, or leaves it unclassified when the families differ. The project reads original names and classifies them itself, so this correction does not reach the pipelines unless the auxiliary table carries it.

## Status and entry point

Status: active diagnostic.

Supported entry point: `diagnose_taxa_classification_coverage.R`.

Run from the repository root with the pinned R version:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/Diagnostics/Data_processing/Taxa/Classification_coverage/diagnose_taxa_classification_coverage.R
```

Add the argument `no_lookup` to skip the online lookup of names the cache does not hold.

## Prerequisites and configuration

- `Data/Input/VegVault.sqlite` (the release named by `vegvault_data.vegvault_version` in the default configuration) and `Data/Input/VegVault_1.0.0.sqlite`. Both are opened read-only.
- The continental rows of `Data/Input/spatial_grid.csv`. Regional and local units lie inside them.
- The age range, dataset types and abiotic variables of the profiles `project_paleo_spatial_continental` (fossil pollen) and `project_modern_spatial_continental` (vegetation plots). Trait names come from all trait domains, as in the trait pipeline.
- `Data/Input/vegvault_2_0_0_combined_pollen_types.csv`: the 116 combined pollen types of VegVault 2.0.0, with their genera and VegVault's kind. It is a copy of three columns of the release evidence file `full_build_dev/combined_pollen_types.csv` (SHA-256 `fb679ee4…`), whose own placement columns come from a development build and are not used.
- The taxospace cache in `Data/Temp/taxospace`, which the diagnostic only reads. Names without a cache file are looked up online (Global Names verifier and GBIF, through `load_taxa_classification()`) and cached in `Data/Temp/vegvault_2_migration/taxospace_lookup/`.

## Outputs and interpretation

All outputs go to `Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/`.

- `taxa_classification_coverage_summary.csv`: names and samples per continent, data type and classification source.
- `taxa_classification_names_to_resolve.csv`: names the auxiliary table and the cache do not cover, with their windows, counts and any online classification.
- `taxa_combined_pollen_types.csv`: the combined pollen types found in the windows, with their placement in VegVault 1.0.0 and 2.0.0, the project's current classification and a proposed auxiliary-table row.
- `taxa_combined_pollen_types_auxiliary_rows_proposed.csv`: the proposed rows in the format of the auxiliary table.

Classification sources:

- `auxiliary_table`: the auxiliary table has a row for the name.
- `taxospace_cache`: the cache holds the name's classification. This includes a file written for another spelling with the same file name (for example `Quercus_petraea.qs` for "Quercus Petraea" on Windows); `load_taxa_classification()` returns it under the requested name.
- `taxospace_lookup`: no cache file; the online lookup classifies the name. A pipeline run will look it up again and cache it.
- `unclassified`: no cache file, and the online lookup finds no plant classification. The pipeline stops on this name.
- `cached_without_ranks`: a cache file exists but holds none of the seven ranks the project uses. The pipeline stops on this name.
- `not_looked_up`: no cache file, and the run skipped the lookup.

Names are counted from lazy queries with the plan builder and vaultkeepr calls of the pipelines. Only records with a value count: `vaultkeepr::extract_data()` drops community records without one (for example presence-only plot records), and the trait loader keeps only existing values. The community queries leave out `vaultkeepr::get_abiotic_data()`: it keeps every vegetation sample and only adds the climate of linked gridpoints, so it cannot change the names, and over the continental fossil-pollen windows it makes the query run for hours. A name the pipeline later drops (for example in deduplication) is still listed.

Proposed rows for combined types (`proposal_rule` in `taxa_combined_pollen_types.csv`):

- `vegvault_2_0_0_family`: the family VegVault 2.0.0 assigns, with no genus. The higher ranks come from the project's classification of that family.
- `lowest_shared_rank`: VegVault 2.0.0 leaves the type unclassified, because its genera (or families) belong to different families. The row keeps each rank, from kingdom down, at which the project classifies all parts alike, and leaves the finer ranks empty. This follows the existing auxiliary rows of such types, for example "Betula Myrica" at Fagales.
- `existing_auxiliary_row`: a type without a 2.0.0 family that already has an auxiliary row keeps it, because that row is a curated choice of the shared rank (for example "Cupressaceae Taxaceae" at Cupressales, where the taxospace classifications of the two families disagree on the order).

`changes_classification` marks the combined types whose proposed row differs from the current classification in any rank. Only those enter `taxa_combined_pollen_types_auxiliary_rows_proposed.csv`.

## Regeneration and retirement

Run after a VegVault release changes or the auxiliary table is edited, and before the first pipeline runs on a new release. Retire when the pipelines report coverage for all windows before extraction-heavy steps, or when VegVault classifications replace the project's own.

# Issue #156 persisted-contract migration report

## Outcome

Issue #156 performs the approved one-time breaking migration of non-CV target names, project-owned result schemas, and generated functional-type and trait quality-control filenames. The supported migration path is a clean target-store rebuild. Active producers and readers expose only the new convention; no legacy aliases or dual schemas were added.

Existing target stores and generated artifacts were not pruned. Their legacy rows and files may remain on disk, but active discovery uses only the new target and filename conventions.

## Inventory evidence

The append-only migration ledger is `Documentation/Implementation_inventories/R_architecture/r_persisted_contract_migration_v1.csv`. It records 35 renamed target bases, the two project-owned result-schema maps, the two artifact-stem maps, and the explicitly preserved Issue #141 targets.

The resolved manifest snapshot is `Documentation/Implementation_inventories/R_architecture/r_manifest_contract_inventory_v1.csv`. It contains 16,830 profile-target rows across all 26 configured profiles, including nested pipe targets and dynamically generated resolution, continent, age, and `tar_map()` suffixes. No approved legacy target base remains in the resolved manifests.

The architecture inventory generator was also updated to recognise literal targets whose `name` argument follows descriptions or other arguments. The regenerated literal-target inventory contains 388 target/source contracts.

## Issue #141 boundary

The public and frozen cross-validation contracts remain unchanged. In particular:

- `model_regularization_for_fit` and `model_evaluation_cross_validated` retain their names and schemas;
- `reference_model_formula`, `scientific_reference_model_formula`, and `decomposition_model_formula` retain their frozen target names;
- the component, regularization, scientific, and decomposition reference manifests retain 24, 32, 30, and 28 targets, respectively;
- profile IDs, profile roles and statuses, target-store paths, CV artifact fields, and CV status vocabulary are unchanged.

The only diffs in the four frozen reference pipeline files are reads of renamed full-data targets: `formula_jsdm_environment`, its generated genus target, and `list_jsdm_variance_partition_genus`.

## Scientific equivalence

Direct legacy-versus-migrated comparisons were run after translating only the approved schema names.

- `evaluate_jsdm()` returned identical model metrics, taxon metrics, convergence values, classes, dimensions, and row order on the same fitted model.
- `write_trait_quality_control_report()` returned identical list values and CSV content after translating list and column names. The `readr` parser metadata changed only because it records the new CSV headers.
- Legacy and newly named Czech paleo and modern-test functional-type `.qs` artifacts were exactly identical as R objects. Their content hashes embedded in the filenames also matched.
- The legacy Czech fitted-evaluation target and the clean-rebuild migrated target were numerically and structurally identical after translating the approved result names.

## Validation evidence

| Validation | Result |
|---|---:|
| Changed R files parsed | 79 passed |
| Focused Issue #156 contract tests | 74 passed |
| Complete repository test suite | 0 failures, 0 warnings, 0 skips |
| Architecture checker | 0 blocking findings; 47 report-only findings |
| Configured manifest profiles | 26 of 26 |
| Czech paleo core isolated clean store | 573 metadata rows, 0 errors |
| Czech paleo resolution isolated clean store | 715 metadata rows, 0 errors |
| Czech modern resolution isolated clean store | 2,514 metadata rows, 0 errors |
| Frozen trait-reference store | 7,986 metadata rows, 0 errors |

The Czech validation used new stores under `Data/targets/issue156_pr_validation/`; it did not call `tar_destroy()` or modify existing Czech stores. The trait-reference workflow used its preserved profile and store path without `fresh_run` and produced `trait_quality_control_report_2026-08-07.csv` under the new filename convention.

## Post-merge migration

After merge, rebuild production target stores through their supported runners. Do not copy, rename, delete, or prune legacy target objects or generated files as part of this migration. The planned full production rerun creates the new contracts naturally; Issue #157 owns final blocking enforcement after that transition.

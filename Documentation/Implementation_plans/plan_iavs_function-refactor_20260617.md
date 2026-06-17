# Plan: R Function Structure, Naming, and IAVS Helper Refactor

## Summary

Refactor in the current working tree, with no commits or staging. Preserve the existing untracked `Documentation/Presentations/IAVS_2026/index.rmarkdown`. Use `git mv` for every moved or renamed tracked file.

Work proceeds in three manual-review phases:

1. Reorganize `R/Functions` into a hybrid domain taxonomy.
2. Conservatively rename unclear or inconsistent functions/files.
3. Extract IAVS helper functions from Quarto/scripts into `R/Functions`, add roxygen docs and tests, then flag unused functions.

Generated website/function documentation will not be regenerated in this pass.

## Key Changes

### Phase 1: Folder Restructure

Keep top-level scientific domains, but add responsibility subfolders. Proposed structure:

- `DataAccess/VegVault`: root VegVault helpers such as extraction and plans.
- `Community`: `Ingest`, `Taxa`, `Classification`, `QualityControl`, `Filtering`, `Transformation`, `Metrics`, `ModernData`.
- `Modelling`: `FitInputs`, `Fitting`, `Diagnostics`, `Evaluation`, `VariancePartitioning`, `SpatialEffects`, `Tuning`, `DecompositionDiagnostics`, `_legacy`.
- `Utility`: only cross-cutting helpers, split into `Config`, `PathsAndStores`, `Parsing`, `Coordinates`, `Pipeline`, `Validation`, `_legacy`.
- `Visualisation`: `DataPreparation`, `VarianceComponents`, `SpatialVariance`, `Networks`, `LegendsAndColours`, `Maps`.
- `Presentation/IAVS`: `DesignTokens`, `PathsAndConfig`, `OraclePalettes`, `OracleScales`, `OracleTheme`, `PanelsAndAnimation`, `Formatting`, `Targets`, `Animations`.
- Apply similar small splits to `Abiotic`, `Time`, `Traits`, and `Prediction`.

Implementation rules:

- Move only with `git mv`.
- Keep tests flat under `R/03_Supplementary_analyses/Testing/testthat` to avoid unnecessary churn.
- Update any hardcoded `source()` paths found by `rg`.
- Confirm `R/___setup_project___.R` and `R/___setup_project_extended___.R` still source recursively without changes unless required.

Validation gate before user review:

- `git status --short`
- source project setup in a fresh `Rscript`
- run affected `targets::tar_manifest()` checks for pipelines that source moved files directly
- run `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`
- run `Rscript R/02_Main_analyses/Run_CZ_test.R`

### Phase 2: Conservative Renames

Rename only high-confidence issues, updating file names, function declarations, roxygen docs, tests, and all call sites.

Initial candidate set:

- Fix typo folder `age_scalling_diagnostic` -> `age_scaling_diagnostic`.
- Prefer British spelling already common in the repo: `summarize_*` -> `summarise_*`.
- Rename non-verb ORACLE helpers where practical:
  - `oracle_continuous_palette()` -> `get_oracle_continuous_palette()`
  - `oracle_discrete_palette()` -> `get_oracle_discrete_palette()`
  - `oracle_palette_values()` -> `get_oracle_palette_values()`
  - `create_oracle_theme()` -> `create_oracle_theme()`
  - `base_terminal_plot()` -> `build_base_terminal_plot()`
- Keep `scale_color_*` and `scale_colour_*` aliases as intentional ggplot-style API compatibility unless tests show unused duplicates can be safely removed.

Do not rename broad domain acronyms such as `jsdm`, `sjsdm`, or `mev` unless their expansion is obvious from nearby docs.

Validation gate before user review:

- run targeted tests for every renamed function
- run full test suite
- run CZ validation script
- provide a rename table with old name, new name, and rationale

### Phase 3: IAVS Helper Extraction

Extract named helper functions from:

- `Documentation/Presentations/IAVS_2026/index.qmd`
- `Documentation/Presentations/IAVS_2026/R/Visualisation/*.R`

Destination policy:

- General reusable helpers go to domain folders.
- ORACLE/slide-specific helpers stay under `Presentation/IAVS`.
- Anonymous `purrr` callbacks may remain inline when they are not reusable named helpers.

Concrete extraction targets:

- `generate_qr_code()` -> presentation QR helper.
- `read_target_or_null()`, `read_target_meta_or_empty()`, `count_successful_targets()` -> target-store utility helpers.
- Merge `format_count()` and `format_slide_count()` into one presentation count formatter.
- Extract duplicate `node_box()` as one schematic node-box helper.
- Extract temporal slide loaders and filters from `temporal_trajectory_animation_figure.R`.
- Extract `build_temporal_trajectory_frame()`, `build_temporal_trajectory_legend()`, and `save_temporal_trajectory_animation()`, reusing existing `build_gif_from_frames()`.
- Extract `format_age_label()` as a reusable age formatter.
- Extract `build_spatial_unit_frame()`.
- Extract `build_prediction_frame()` and `save_prediction_animation()`.
- Extract nested `get_vegvault_scalar()` as `read_vegvault_scalar()` only if it remains a named reusable helper after refactor.

For each new or changed function:

- write or update roxygen spec first
- create one function per file
- create or update `test-<function_name>.R`
- use subagent workers for test files only, with instructions to write tests from roxygen/spec stubs, not implementation bodies
- verify new tests fail against stubs before implementation, then pass after implementation

Validation gate before user review:

- targeted tests for every extracted function
- full test suite
- `Rscript Documentation/Presentations/IAVS_2026/R/render.R`
- `Rscript R/02_Main_analyses/Run_CZ_test.R`

## Unused Function Report

After Phase 3, produce a report only; do not delete functions.

Method:

- run static usage scan across `.R`, `.qmd`, and `.Rmd`
- exclude each function’s own definition file
- separately flag `_outdated` functions
- manually review low-hit candidates for dynamic use through targets, examples, aliases, or sourced scripts
- report candidates with function name, file path, hit count, and reason for caution

Known first-pass candidates include some presentation wrappers and `_outdated` helpers, but these are not deletion decisions.

## Assumptions

- Work stays in the current working tree, per your choice.
- No commits, staging, pushes, or branch operations.
- Generated documentation under website/function docs is left untouched.
- Tests remain in the existing flat `testthat` layout.
- The implementation pauses after each phase for your manual inspection.

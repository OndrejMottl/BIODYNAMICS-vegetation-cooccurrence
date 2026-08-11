# Issue 155 — Pipeline, Prediction, Visualisation, and Presentation Refactor

**Status:** Implemented and validated on `refactor/issue155-pipeline-prediction-visualisation-presentation`; unstaged, uncommitted, and unpublished.

## Summary

Implement Issue #155 as the next child of #149, starting from clean `main` at `5b9df9bd`, the merge commit of PR #163.

The refactor will:

- eliminate `R/Functions/Utility/` completely;
- give configuration, stores, orchestration, prediction, and visualisation explicit ownership;
- localise IAVS-only helpers under the IAVS presentation;
- clarify `plot_*`, `save_*`, `render_*`, `load_*`, `resolve_*`, and predicate contracts;
- preserve scientific results, target names, artifact schemas, store layouts, configuration keys, seeds, and CV behaviour; and
- use one branch and one PR with capability-ordered commits.

## Interface and Ownership Changes

### Utility dissolution

Move active helpers and mirrored tests using `git mv`:

- configuration, project loading, target metadata, stores, execution, monitoring, and progress output to `Pipeline/{Configuration,Definitions,Stores,Orchestration}`;
- coordinates and spatial catalogue access to `Data/Spatial`;
- row-name parsing, sample alignment, and sample validation to `Data/Samples`;
- VegVault validation and generic dated-file selection to `Data_access/{Vegvault,Files}`; and
- functional-type classification path resolution to `Data/Traits/Ingest`.

Move `load_project_functions()` atomically with every reference in the main and extended setup, architecture checker/generator, setup tests, and documentation generation. Verify the loaded symbol set before semantic renames.

Retire caller-free `_legacy/get_spatial_model_params.R` and `_legacy/prepare_data_for_fit.R`; completion requires that `R/Functions/Utility/` no longer exists. If a second caller scan finds a live consumer, stop and revise the plan rather than adding a compatibility wrapper.

### Approved global API renames

Apply each rename atomically across production callers, tests, documentation, inventories, and pipeline commands:

- Data: `get_coords()` to `extract_dataset_coordinates()`; `get_spatial_window()` to `load_spatial_window()`; `get_continent_id_from_scale_id()` to `resolve_continent_ids_from_scale_ids()`; `load_continental_rows()` to `load_continental_spatial_grid_rows()`.
- Samples: `get_age_from_string()` to `extract_age_from_sample_names()`; `get_dataset_name_from_string()` to `extract_dataset_name_from_sample_names()`; both `add_*_column_from_rownames()` helpers to `prepare_*_column_from_rownames()`.
- Validation and paths: `check_presence_of_vegvault()` to `validate_vegvault_presence()`; `get_latest_dated_file_path()` to `resolve_latest_dated_file_path()`; `get_functional_type_classification_path_from_store()` to `resolve_functional_type_classification_path_from_store()`.
- Configuration and stores: `get_preprocessing_controller()` to `build_preprocessing_controller()`; `get_model_tuning_params()` to `load_model_tuning_parameters()`; its scale/resolution variant receives the same `load_*` form; `get_scale_id_from_store()` to `resolve_scale_id_from_store()`; `read_targets_store_meta()` to `load_targets_store_metadata()`; `check_target_succeeded()` to `has_target_succeeded()`.
- Pipeline: `get_new_targets_errors()` to `extract_new_target_errors()`; `monitor_pipeline_progress()` to `run_pipeline_progress_monitor()`; `save_progress_visualisation()` to `save_pipeline_progress_visualisation()`.
- Prediction: `assert_prediction_probabilities()` to `validate_prediction_probabilities()`; `read_spatial_resolution_prediction_inputs()` to `load_spatial_resolution_prediction_inputs()`.
- Visualisation: `build_map_panel()` to `plot_spatial_anova_map_panel()`; `mix_variance_component_colours()` to `compute_variance_component_colours()`; promote the substantive nested helper as `collapse_spatial_variance_observation_id()`.

Inline the single use of `coerce_null_to_na_integer()` and retire it instead of creating another generic helper. Unlisted APIs retain their signatures and return structures.

### Explicit behavioural contracts

- Keep `run_pipeline()`'s public signature and behaviour unchanged, including fresh-run destruction, interpolation prebuild, warnings, error propagation, targets, and stores.
- Introduce one internal `resolve_pipeline_store_path(pipeline_script)` used by execution, metadata, progress saving, and monitoring.
- `plot_pipeline_progress_visualisations()` returns named full/static visualisation objects without writing.
- `save_pipeline_progress_visualisation()` performs writes and returns named output paths.
- `run_pipeline_units_with_status()` gains `verbose = TRUE`; all messages are conditional on it.
- All scientific `plot_*` helpers remain pure object-returning functions. Calling scripts retain `ggview::canvas()` and `ggview::save_ggplot()` ownership.

## Implementation Sequence

1. **Baseline and path-only Utility dissolution**
   - Record clean source, tests, manifests, Czech smoke counts, inventories, and architecture findings using the PR #163 validation procedure.
   - Move active functions and tests without renaming; update loader/bootstrap references atomically.
   - Compare loaded symbols before and after, allowing only the two explicitly retired legacy symbols.
2. **Data and access contracts**
   - Apply data, sample, VegVault, classification-path, and dated-file renames.
   - Preserve columns, row names, ordering, coordinate projections, path-selection rules, and validation errors.
3. **Configuration and store contracts**
   - Organise loading, generation, validation, model-tuning parameters, project definitions, spatial-model stores, and target metadata.
   - Extract substantive nested configuration validators into normal one-function files with mirrored tests.
4. **Orchestration and progress output**
   - Refactor `run_pipeline()` to delegate store resolution, interpolation prebuild, metadata loading, new-error extraction, execution status, and progress output.
   - Separate pure progress-object construction from file writing and interactive monitoring.
5. **Historical prediction contracts**
   - Keep existing contract-based Prediction folders; apply approved names, mirrored tests, and local-object cleanup.
   - Preserve historical numerical results and do not introduce the future prediction context owned by #136.
6. **Visualisation contracts**
   - Organise preparation, plots, legends, map panels, and network plots by scientific capability.
   - Promote and test the observation-collapse helper while keeping plot helpers pure.
7. **IAVS localisation**
   - Move retained helpers to `Documentation/Presentations/IAVS_2026/R/Functions/` and add a deterministic presentation-local loader.
   - Update render entry points, tests, and website links atomically; remove proven-dead compatibility wrappers and helpers after a second caller scan.
8. **Enforcement and generated documentation**
   - Make #155-owned rules blocking and regenerate inventories, function documentation, coverage reports, website/manuscript outputs, and an Issue 155 final-validation report.

## Acceptance Criteria and Boundaries

- Czech smoke retains the PR #163 target counts: 127 paleo-core, 258 paleo spatial-resolution, and 246 modern spatial-resolution.
- Full tests pass without regression from the PR #163 baseline coverage; every changed function has focused tests.
- Manifest target names are identical, and commands are structurally equivalent after normalising only approved function-symbol renames.
- No compatibility wrappers, new dependencies, persisted-name migrations, or unrelated scientific changes are introduced.
- Issue #136 retains prediction contexts, climate backends, scenario/horizon schemas, and future-prediction pipelines.
- Issues #140–141 retain CV algorithms, scheduling, schemas, targets, stores, and performance policy; #155 changes only direct shared-helper callers.
- Issue #156 retains persisted target, artifact-field, store-layout, and profile-key renames.
- Issue #157 retains repository-wide enforcement and final architecture-map closure; #155 makes only its own findings blocking.
- Staging, commits, pushing, and PR creation require separate explicit authorization.

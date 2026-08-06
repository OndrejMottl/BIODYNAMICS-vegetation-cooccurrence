# Plan: Issue 154 non-CV modelling functions

**Date:** 2026-08-03

**Status:** Approved for staged implementation

**Issue:** [#154](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/154)

**Umbrella:** [#149](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/149)

**Pattern:** [PR #162](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/pull/162)

---

## Summary

Implement Issue #154 as one layered pull request from the clean `main` commit
`b9acfeae`, following PR #162's path-first, capability-by-capability pattern.

- Work on `refactor/issue154-modelling` in the current worktree.
- Preserve scientific behaviour, function outputs, target names, artifact
  schemas, seeds, convergence semantics, and store compatibility.
- Keep `R/Functions/Modelling/Cross_validation/**` under #141.
- Leave persisted renames to #156 and pipeline/store reorganisation to #155.
- Use dependency-ordered work chunks for ownership, fit inputs, fitting,
  runtime diagnostics, spatial effects, evaluation, variance partitioning,
  decomposition, legacy retirement, and final validation.
- Treat one reviewable pull request as the eventual deliverable. Pushing and
  opening it require separate explicit user confirmation.

## Working agreement

After every work chunk:

1. Run focused validation and `git diff --cached --check`.
2. Stage only files belonging to that chunk.
3. Report staged files, validation results, residual risks, and a suggested
   durable commit message.
4. Stop and wait for user review.
5. Treat `continue` as permission for the next chunk only.

Never commit, push, open a pull request, or modify remote GitHub state without
a separate explicit instruction. Before starting another chunk, verify that
the preceding staged changes were committed or otherwise resolved.

## Scope and ownership boundaries

### Issue 154 ownership

- Model input construction and scaling.
- Non-CV model fitting and runtime diagnostics.
- Spatial-effect basis computation and projection.
- Fitted-model evaluation and result loading.
- Variance partitioning.
- Predictive decomposition and its diagnostic route helpers.
- Proven-unused HMSC legacy functions.

### Explicit deferrals

- Leave `prepare_model_fold_input()` and
  `prepare_fold_spatial_predictors()` unchanged for #141.
- Leave `check_target_succeeded()`, `read_targets_store_meta()`, and
  `coerce_null_to_na_integer()` unchanged and record them as #155 work.
- Do not change CV algorithms, tuning policy, scientific estimands,
  prediction features, persisted names, or public artifact schemas.

## Approved interface changes

| Capability | Current interface | Approved interface |
|---|---|---|
| Fit inputs | `assemble_data_to_fit()` | `build_jsdm_fit_input()` |
| Fit inputs | `make_env_formula()` | `build_jsdm_environment_formula()` |
| Fit inputs | `apply_scale_attributes()` | `scale_predictors_with_training_attributes()` |
| Fitting | `check_convergence_jsdm()` | `diagnose_jsdm_convergence()` |
| Runtime | `check_cuda_gpu_runtime()` | `diagnose_sjsdm_gpu_runtime()` and `validate_sjsdm_gpu_runtime()` |
| Runtime | `verify_sjsdm_setup()` | `diagnose_sjsdm_setup()` |
| Spatial effects | `compare_spatial_mev_subspaces()` | `compute_spatial_mev_subspace_similarity()` |
| Evaluation | `read_spatial_model_results()` | `load_spatial_model_results()` |
| Evaluation | `read_model_evaluation_target()` | `load_model_evaluation_target()` |
| Variance | `get_anova()` | `compute_jsdm_variance_partition()` |
| Variance | `recalculate_anova_components()` | `compute_shapley_variance_components()` |
| Variance | `extract_anova_fractions()` | `extract_jsdm_variance_fractions()` |
| Variance | `aggregate_anova_components()` | `aggregate_jsdm_variance_components()` |
| Decomposition | `get_decomposition_route_sample_ids()` | `select_decomposition_route_samples()` |
| Decomposition | `make_decomposition_diagnostic_routes()` | `build_decomposition_diagnostic_routes()` |
| Decomposition | `make_decomposition_env_formula()` | `build_decomposition_environment_formula()` |
| Decomposition | `make_repeated_cv_indices()` | `build_repeated_diagnostic_fold_indices()` |
| Decomposition | `refresh_cz_decomposition_upstream()` | `run_decomposition_upstream_refresh()` |
| Decomposition | `run_decomposition_route_cv()` | `run_decomposition_diagnostic_folds()` |
| Decomposition | `summarise_decomposition_routes()` | `summarise_decomposition_diagnostic_routes()` |

Keep `fit_jsdm_model()` and existing canonical `compute_*`, `evaluate_*`,
`prepare_*`, `project_*`, and `summarise_*` interfaces unless a later work
chunk demonstrates a documented ownership problem.

Renamed internal functions receive no compatibility aliases. Update active
callers, tests, diagnostic scripts, and generated references atomically.
Persisted targets, result columns, statuses, and provenance fields remain
unchanged.

## Work chunks

### 1. Plan and contract baseline

- Create the working branch and save this implementation plan.
- Record functions, callers, affected manifests, target names, schema tests,
  and fixed-seed numerical fixtures.
- Make no production-code changes.

Suggested commit message:
`Document the non-CV modelling refactor contract`

### 2. Ownership and directory layout

- Move active functions and tests into the approved modelling hierarchy using
  `git mv`.
- Keep the chunk path-only and verify that the loaded-symbol set is unchanged.
- Record #141 and #155 deferrals in the architecture inventories.

Suggested commit message:
`Organise modelling functions by capability ownership`

### 3. Model input preparation

- Apply the three fit-input renames while preserving arguments, defaults,
  formulas, scaling attributes, and returned list names.
- Keep fold-local preparation untouched for #141.
- Validate through the `data_model_input` target.

Suggested commit message:
`Clarify model input construction and scaling interfaces`

### 4. Model fitting and runtime diagnostics

- Keep `fit_jsdm_model()` as the public orchestrator.
- Extract private helpers for response preparation, predictor construction,
  device selection, and early-stopping resolution.
- Separate non-aborting diagnostics from strict validation and remove
  machine-specific setup paths.
- Preserve fitting parameters, seeds, regularisation, selected-model
  behaviour, and the returned model structure.

Suggested commit message:
`Separate model fitting from runtime diagnostics`

### 5. Spatial effects

- Organise basis, projection, and diagnostic functions.
- Extract exact and fast MEV strategies only when fixed-seed equivalence is
  demonstrated.
- Preserve algorithms, projection state, provenance, output dimensions, and
  deterministic behaviour.

Suggested commit message:
`Organise spatial effect basis and projection logic`

### 6. Evaluation and result loading

- Apply the evaluation loader names.
- Extract private store-loading, empty-result, fitted/predictive metric,
  calibration, and provenance helpers.
- Preserve metric definitions, output columns, statuses, and missing-result
  behaviour.

Suggested commit message:
`Clarify model evaluation and result loading contracts`

### 7. Variance partitioning

- Apply variance and Shapley terminology to reusable functions.
- Extract private component-lookup and Shapley-allocation helpers.
- Preserve all `model_anova` and by-age target names and artifact schemas.

Suggested commit message:
`Clarify variance partitioning and Shapley calculations`

### 8. Predictive decomposition and diagnostics

- Separate reusable predictive-decomposition calculations from diagnostic
  route orchestration.
- Apply the approved canonical names.
- Extract repeated fold-loss, variant-fit, empty-result, and input-loading
  logic.
- Update diagnostic callers without moving their scripts, which remain #155
  work.

Suggested commit message:
`Separate predictive decomposition from diagnostic routes`

### 9. Legacy HMSC retirement

- Repeat active-caller and generated-documentation scans.
- Remove the eight unused HMSC functions, obsolete tests, and stale
  references.
- Add architecture assertions preventing their return.

Suggested commit message:
`Retire unused HMSC modelling functions`

### 10. Architecture, documentation, and integration validation

- Regenerate inventories and make migrated Issue #154 placement, naming,
  mirrored tests, and retirement paths blocking.
- Regenerate function and dependent documentation artifacts.
- Run the complete test suite and supported three-pipeline Czechia smoke
  workflow.
- Complete the mandatory read-only change review and resolve actionable
  findings.
- Compare final manifests, schemas, statuses, provenance, and fixed-seed
  results with this baseline.

Suggested commit message:
`Enforce and document the modelling architecture`

## Validation requirements

For every capability chunk:

- Add or move specification tests before semantic implementation.
- Parse changed R files and source `R/___setup_project___.R` in a clean session.
- Run focused mirrored tests, including happy paths, edge cases, validation
  failures, empty results, non-convergence, and relevant runtime diagnostics.
- Compare affected manifests and persisted target-name sets with the baseline.
- Run a fresh dependency-closed capability slice.
- Compare classes, dimensions, names, schemas, statuses, provenance, and
  fixed-seed numerical results using existing tolerances.
- Run `git diff --cached --check` after staging.

Final acceptance additionally requires:

- The architecture inventory generator and blocking checker.
- `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`.
- `Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R`.
- The repository master documentation renderer.
- No stale old symbols, paths, generated pages, or unintended persisted-name
  changes.
- A clean mandatory change review against all repository instructions.

## Contract baseline

### Git and architecture inventories

- Baseline commit: `b9acfeae7b1c0955cc702a5943ed86cccdcc9fd6`.
- Baseline branch point: local and `origin/main` were identical.
- The worktree was clean before creating `refactor/issue154-modelling`.

| Inventory | SHA-256 |
|---|---|
| `r_function_inventory_v1.csv` | `B1F3854B61A91E6E04443CD4F3E7EE8749DA1FE0AE460E95C0A77F7EDF5CEF8B` |
| `r_contract_inventory_v1.csv` | `5AE3DAAEE8BB7991757268B00905CF229F7F35D50CB6BC876A7C3C5B5C31CF4A` |
| `r_script_path_inventory_v1.csv` | `B6DEE55D53A6D92A56486E1075D85D495BD84267CB48A75B5AC298999347C281` |

The function inventory contains 56 active non-CV modelling functions:

| Current capability | Functions |
|---|---:|
| `Decomposition_diagnostics` | 13 |
| `Diagnostics` | 4 |
| `Evaluation` | 9 |
| `Fit_inputs` | 11 |
| `Fitting` | 1 |
| `Spatial_effects` | 10 |
| `Tuning` | 4 |
| `Variance_partitioning` | 4 |

The inventory records 53 distinct matching test paths. Twenty functions require
an owning-issue naming decision, and nine functions contain nested helpers to
review. These are the exact review sets encoded by
`r_function_inventory_v1.csv`; regeneration must resolve Issue #154 rows while
retaining the explicit #141 and #155 deferrals.

### Caller baseline

The 56 functions are called by these active modelling pipe segments:

- `pipe_segment_model_input.R` and `pipe_segment_model_prepare_response.R`;
- `pipe_segment_model_spatial_shared.R` and
  `pipe_segment_model_spatial_samples.R`;
- `pipe_segment_model_assemble.R` and `pipe_segment_model_fit.R`;
- `pipe_segment_model_anova.R` and
  `pipe_segment_model_summary_by_age.R`; and
- `pipeline_paleo_local_cv_decomposition_reference.R`.

The shared segments are consumed by six pipeline entry points:

- `pipeline_paleo_core.R`;
- `pipeline_paleo_resolution_test.R`;
- `pipeline_paleo_spatial_resolution.R`;
- `pipeline_paleo_temporal.R`;
- `pipeline_modern_spatial_resolution.R`; and
- `pipeline_modern_spatial_resolution_test.R`.

Five age-scaling decomposition diagnostics, four other modelling/pipeline
diagnostics, and two spatial sensitivity/repair scripts are also active
callers. Their paths remain owned by #155; Issue #154 updates only their calls
to renamed modelling functions.

### Manifest and target-name baseline

Manifest digests were computed under `R_CONFIG_ACTIVE=project_cz_paleo` from
newline-delimited `target_name=command` records. The digest therefore detects
both target-name and command-expression drift.

| Pipeline | Targets | MD5 digest |
|---|---:|---|
| `pipeline_paleo_core.R` | 127 | `fc99e03c3a6078e041dcdadd5bd2476f` |
| `pipeline_paleo_resolution_test.R` | 258 | `df678c90706df2742e3faa160e39e6c7` |
| `pipeline_paleo_spatial_resolution.R` | 232 | `3f57dfd086433658037dd223c1ca6a18` |
| `pipeline_paleo_temporal.R` | 663 | `10479859df70e1c93513684924b34e7f` |
| `pipeline_modern_spatial_resolution.R` | 233 | `d4392e5ab41f0fc7cef2430124ee992d` |
| `pipeline_modern_spatial_resolution_test.R` | 246 | `9f3de959f972f756a03cdb5b938353f7` |
| `pipeline_paleo_local_cv_decomposition_reference.R` | 28 | `15eca23b0c24f4d149eacbf67e84402b` |

Protected shared modelling targets include:

- `data_community_model_matrix`, `data_abiotic_wide`,
  `data_abiotic_scaled_list`, and `data_community_prepared`;
- `config_spatial_predictors`, `data_coords_projected`,
  `list_spatial_mev_core_basis`, `data_spatial_mev_core`,
  `data_spatial_mev_provenance`, and `data_spatial_mev_samples`;
- `data_spatial_scaled_list`, `data_model_input`, `model_formula`,
  `model_jsdm`, `model_jsdm_standard_errors`, `model_jsdm_selected`, and
  `model_evaluation_fitted`; and
- `model_anova`, `list_model_anova_by_age`,
  `data_anova_components_by_age`, and
  `data_anova_components_by_age_percentage`.

The decomposition reference pipeline declares 28 persisted-internal contracts
owned by #156. Its complete target-name set is represented by the manifest
digest and `r_contract_inventory_v1.csv`; none may be renamed in Issue #154.

### Schema and fixed-seed fixture baseline

Existing tests are the executable schema and numerical baseline. Their file
hashes prevent silent weakening while functions and tests move together.

| Capability fixture | SHA-256 |
|---|---|
| `test-assemble_data_to_fit.R` | `9C597FF58B77CB52FA672D841FDF397A2FDD3AE538FED10B624226AD16C2059D` |
| `test-apply_scale_attributes.R` | `E5EA110A2F1725C419923A4B72BC3D8451D305446952BC351F6B4BDEF3A92B08` |
| `test-make_env_formula.R` | `CE23D975DE6DF0F2176C307D0E49FAA2F08B4137029D5F07A552731E614EE0A8` |
| `test-fit_jsdm_model.R` | `C335E6AEE0A08958E8CDD805B68655C646A2F30E42009132EFC756F8B6F3DC8C` |
| `test-check_convergence_jsdm.R` | `A0DB0743817011AB0565136A792DA79CBAEA4A96B756DE31FC383B06370C813B` |
| `test-compute_spatial_mev_basis.R` | `2F737D5CD275B3B1FBC3693796B7BBA9B5A29AC3A81596306BADBD286C215474` |
| `test-project_spatial_mev_basis.R` | `5512579AC5AE1B5BEB4E4B233C3CE4CA750BDDB3F6025708C03A5EDA35376EAE` |
| `test-read_spatial_model_results.R` | `08F6864F3BD949001F4B6DC40C8DA64B4C9204A0B3BF046EBB7FD31DC78B18ED` |
| `test-evaluate_jsdm.R` | `2007981A09EE7DA2D5EDDC43120FF8BA1E8A512274858CAEAC841CDC478BD9BB` |
| `test-get_anova.R` | `7EA0011E9ED79C032F7F36E0B0FBC730B4C1D5D7C876801A0F5B38B0F3105DCE` |
| `test-recalculate_anova_components.R` | `F5C5F437B4169C0F5FBCF8D9CE79850A2DF9E9C2D9A857DD05CB89993FC218F7` |
| `test-compute_decomposition_prediction_metrics.R` | `3057CC4CC507D900778B16205972A4820146E2BA7AD65896062DBCFDAB660D71` |
| `test-compute_predictive_decomposition_shares.R` | `012A5BFEBDABE456E53A5E834D07A51F4E7045018BC7B07B409E365E311730BF` |
| `test-run_decomposition_route_cv.R` | `942214EAA9B44F56EE7C15B6B0ACC8204BB840041779B685EF515DF29AD1DFB0` |

These fixtures cover named structures, result classes and dimensions,
statuses, provenance, formulas, scaling attributes, variance fractions,
decomposition shares, and fixed-seed fitting or spatial calculations. Later
chunks may rename and strengthen them, but must preserve or explicitly extend
their behavioural assertions.

### Legacy baseline

`R/Functions/Modelling/_legacy` contains eight HMSC functions and is excluded
from the recursive loader. Seven have no active callers. The only match for
`check_and_prepare_data_for_fit()` outside legacy and outdated tests is a stale
`@seealso` entry in `make_env_formula.R`. Nine HMSC-related tests remain under
`Testing/testthat/_outdated` and are excluded by the test runner. Repeat this
caller scan immediately before retirement.

## Final interface and access audit

Before final acceptance in Chunk 10:

- Recheck every function under an `Internal/` directory and every dot-prefixed
  helper. Internal functions should be limited to small, simple, or repetitive
  implementation details.
- Treat `.fit_decomposition_variant()` as an explicit first candidate for
  promotion to a normal reusable function. Promote any substantial domain
  workflow that has its own meaningful contract, tests, or documentation.
- Scan all active functions under `R/Functions/` again for `$` access, not only
  files changed by Issue #154. Resolve in-scope occurrences and explicitly
  record the owner of any justified deferral.
- Require the final change review to confirm that no substantial reusable
  function remains accidentally internal and no prohibited `$` access remains
  in active functions.

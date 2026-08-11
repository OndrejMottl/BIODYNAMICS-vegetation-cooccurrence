# Issue 154 internal-function and dollar-access audit

## Scope

This audit closes the final interface and access checks added to the Issue #154 implementation plan. It covers active functions loaded from `R/Functions/`, excluding exact `_legacy` directories.

## Internal-function review

The review considered all 20 functions in a modelling `Internal/` directory and the one additional dot-prefixed runtime helper. Internal functions are retained only when they are small, simple, or repetitive implementation details.

### Promoted to normal functions

| Former symbol | Normal function | Reason |
|---|---|---|
| `.fit_decomposition_variant()` | `fit_decomposition_variant()` | Owns the substantial fit, convergence, prediction, failure, and metric workflow for one diagnostic variant. |
| `.compute_predictive_fold_shares()` | `compute_predictive_fold_shares()` | Implements reusable loss and higher-is-better decomposition mathematics and two stable result schemas. |
| `.summarise_predictive_model_metrics()` | `summarise_predictive_model_metrics()` | Implements a reusable typed aggregation contract for predictive metrics. |
| `.compute_fast_spatial_mev_basis()` | `compute_fast_spatial_mev_basis()` | Owns the fixed-seed Nyström algorithm, validation, and projection state. |
| `.allocate_shapley_variance_components()` | `allocate_shapley_variance_components()` | Implements the domain-level Shapley allocation calculation. |
| `.diagnose_torch_cuda_details()` | `diagnose_torch_cuda_details()` | Exposes a substantial, structured, non-aborting runtime diagnostic contract. |

### Retained as internal functions

| Internal symbol | Reason |
|---|---|
| `.build_empty_decomposition_variant()` | Repetitive typed failure-schema construction. |
| `.load_decomposition_model_fitting_config()` | Small fallback-loading adapter. |
| `.load_decomposition_target()` | Small injected target-reader adapter. |
| `.resolve_decomposition_fold_loss()` | Small unique-value lookup. |
| `.build_empty_spatial_model_results()` | Repetitive typed empty-schema construction. |
| `.fit_binary_calibration_model()` | Small warning- and error-capture adapter around one model fit. |
| `.load_successful_model_target()` | Small metadata gate and safe-read adapter. |
| `.summarise_fitted_auc()` | Simple typed finite-value summary. |
| `.summarise_model_provenance()` | Simple first-row and typed-default normalization. |
| `.build_sjsdm_predictor_structure()` | Small three-route constructor adapter. |
| `.prepare_sjsdm_response()` | Small response and family conversion. |
| `.resolve_sjsdm_device()` | Small runtime-setting normalization. |
| `.resolve_sjsdm_early_stopping()` | Small three-route patience normalization. |
| `.compute_exact_spatial_mev_basis()` | Small direct adapter around the exact engine. |
| `.lookup_jsdm_variance_component()` | Small component lookup with a zero default. |

## Dollar-access scan

The repository-wide scan covered 325 active function files. It found 247 raw `$` matches across 38 files. Raw matches include access expressions, regular expressions, documentation text, error messages, and generated SCSS strings.

| Owner | Files | Raw matches | Disposition |
|---|---:|---:|---|
| #154 non-CV modelling | 1 | 1 | The only match is the regular-expression anchor `"\\d+$"`; there is no prohibited access. |
| #141 cross-validation | 1 | 9 | Deferred with the CV implementation; matches access injected Torch/Python APIs. |
| #150 architecture loader | 1 | 1 | The only match is the file-extension anchor `"[.]R$"`; there is no prohibited access. |
| #153 data functions | 5 | 13 | Deferred to the data-architecture owner; the raw set mixes tidy-evaluation access and text. |
| #155 shared functions and workflows | 30 | 223 | Deferred to shared utility, prediction, presentation, visualisation, and tuning ownership; the raw set mixes access and literal text. |

`check_target_succeeded()` remains explicitly owned by #155 as agreed in the Issue #154 plan. Its `.data$name` and `.env$target_name` access is therefore recorded, not changed here. No `$` access remains in the active non-CV modelling functions owned by Issue #154.

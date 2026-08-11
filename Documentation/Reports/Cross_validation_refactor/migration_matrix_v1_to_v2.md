# Cross-validation migration matrix from v1 to v2

**Owning issue:** #141

## Compatibility policy

Loaders attempt the canonical v2 target first. If it is absent, they read the complete documented v1 target group, validate the frozen v1 schema, convert it in memory to v2, validate the resulting envelope, and return it without modifying the source store.

## Target groups

| V2 target | V1 source target or target group | Conversion result |
|---|---|---|
| `list_cross_validation_shared_design_artifact` | Shared sample-ID, location, resolution, grid, calibration, and assignment targets | `cross_validation_shared_design` envelope |
| `list_cross_validation_design_artifact` | Branch location, resolution, initial/final assignment, diagnostic, and feasibility targets | `cross_validation_design` envelope |
| `list_sjsdm_cv_tuning_artifact` | Candidate, schedule where available, tuning metrics/summary, timings, execution provenance, and prediction cache targets | `sjsdm_cv_tuning` envelope; historical reporting only unless the source contains the complete cache contract |
| `list_sjsdm_regularization_selection_artifact` | Unit selection, tier artifact row, and final-fit selection targets | `sjsdm_regularization_selection` envelope |
| `list_sjsdm_cv_prediction_artifact` | `data_sjsdm_out_of_fold_predictions` and `data_sjsdm_out_of_fold_diagnostics` | `sjsdm_cv_predictions` envelope |
| `list_sjsdm_cv_evaluation_artifact` | Pooled evaluation, fold metrics, fold summaries, repeat distributions, and model provenance targets | `sjsdm_cv_evaluation` envelope |
| `list_sjsdm_tier_tuning_artifact` | Tier regularization artifacts, source loss, candidate aggregation, selection sensitivity, and available round decisions | `sjsdm_tier_tuning` envelope |
| `list_sjsdm_common_regularization_artifact` | Common regularization artifacts, candidate aggregation, model index, and sensitivity provenance | `sjsdm_common_regularization` envelope |

## Failure policy

- A partially available v1 target group is an error, not an empty or skipped artifact.
- Unknown columns, wrong column order or types, duplicate keys, unsupported status values, and incompatible context/candidate hashes fail closed.
- Missing optional tier selection is represented by the exact typed-empty v2 payload only when the v1 scientific contract explicitly permits no tier selection.
- No converter imports v1 fitted model objects or tuning prediction caches into an active v2 unit graph.
- No converter writes into or deletes from the v1 store.

## Retirement

V1 readers are temporary compatibility code. Issue #168 removes them after retained external stores have been regenerated and audited as native v2. `r_cv_v1_compatibility_exceptions_v2.csv` records #141 as the migration owner and #168 as the expiry issue for every temporary compatibility boundary.

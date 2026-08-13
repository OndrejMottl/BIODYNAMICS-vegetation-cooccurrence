# Cross-validation migration matrix from v1 to v2

**Owning issue:** #141
**Compatibility retirement:** #168

## Current policy

The migration is complete. Active loaders accept canonical native-v2 artifacts only. They do not probe historical target names, assemble v2 envelopes from v1 tables, or import v1 fit objects or prediction caches.

Every active read validates the exact `2.0.0` envelope and registered payload. Provenance must state `source_schema_version = "2.0.0"`, `migration_applied = FALSE`, and `migration_function = NA`.

## Completed historical mapping

The table below is retained as migration history. It no longer describes executable reader behavior.

| V2 target | Historical v1 source target or target group | Completed v2 result |
|---|---|---|
| `list_cross_validation_shared_design_artifact` | Shared sample-ID, location, resolution, grid, calibration, and assignment targets | `cross_validation_shared_design` envelope |
| `list_cross_validation_design_artifact` | Branch location, resolution, initial/final assignment, diagnostic, and feasibility targets | `cross_validation_design` envelope |
| `list_sjsdm_cv_tuning_artifact` | Candidate, schedule, tuning metrics/summary, timings, execution provenance, and prediction-cache targets | `sjsdm_cv_tuning` envelope |
| `list_sjsdm_regularization_selection_artifact` | Unit selection, tier artifact row, and final-fit selection targets | `sjsdm_regularization_selection` envelope |
| `list_sjsdm_cv_prediction_artifact` | Out-of-fold predictions and diagnostics | `sjsdm_cv_predictions` envelope |
| `list_sjsdm_cv_evaluation_artifact` | Pooled evaluation, fold metrics, summaries, repeat distributions, and model provenance | `sjsdm_cv_evaluation` envelope |
| `list_sjsdm_tier_tuning_artifact` | Tier regularization artifacts, candidate aggregation, sensitivity, and round decisions | `sjsdm_tier_tuning` envelope |
| `list_sjsdm_common_regularization_artifact` | Common regularization artifacts, candidate aggregation, model index, and sensitivity provenance | `sjsdm_common_regularization` envelope |

## Historical-data policy

Frozen v1 fixtures, manifests, validation records, correctness reports, benchmark evidence, and old production stores remain immutable historical evidence. They are not runtime compatibility inputs. Old main-production outputs are superseded until #171 performs definitive native-v2 production reruns.

Missing canonical targets, unknown versions, raw tables, malformed payloads, migrated provenance, duplicate keys, target errors, and invalid content hashes fail closed. The one exception is a genuinely unavailable tier decision, which retains its documented typed-empty native-v2 result.

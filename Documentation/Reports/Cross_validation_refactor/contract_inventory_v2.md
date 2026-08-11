# Cross-validation contract inventory v2

**Schema version:** `2.0.0`
**Owning issue:** #141
**Registry contract hash (MD5):** `717435760b653dce608ce51380ec0fb1`

The resolved target graph is recorded in `r_manifest_contract_inventory_v2.csv`: 18,256 target rows across 26 configured profiles. The historical v1 manifest inventory remains unchanged.

## Artifact envelope

Every public persisted cross-validation artifact is a named list with exactly five top-level fields in this order: `schema_version`, `artifact_type`, `payload`, `provenance`, and `content_hash`.

- `schema_version` is the character scalar `2.0.0`.
- `artifact_type` is one registered character scalar.
- `payload` is a non-empty named list whose names are defined below.
- `provenance` is a one-row tibble containing the common provenance fields plus artifact-specific fields.
- `content_hash` is an xxHash64 digest of the schema version, artifact type, payload, and stable provenance.

The content hash excludes `created_at`, `source_schema_version`, `migration_applied`, and `migration_function`. These fields describe materialization or conversion, not scientific content.

Common provenance fields are `created_at`, `pipeline_id`, `configuration_profile`, `source_schema_version`, `migration_applied`, and `migration_function`. Native v2 writers use source schema `2.0.0`, migration flag `FALSE`, and a missing migration function.

## Public targets and payloads

| Public target | Artifact type | Required payload names |
|---|---|---|
| `list_cross_validation_shared_design_artifact` | `cross_validation_shared_design` | `data_sample_ids`, `data_locations`, `data_fold_resolution`, `data_grid_candidates`, `data_grid_calibration`, `data_assignments`, `data_assignment_provenance` |
| `list_cross_validation_design_artifact` | `cross_validation_design` | `data_locations`, `data_fold_resolution`, `data_assignments_initial`, `data_partition_diagnostics_initial`, `data_assignments`, `data_partition_diagnostics`, `data_feasibility`, `data_route_provenance` |
| `list_sjsdm_cv_tuning_artifact` | `sjsdm_cv_tuning` | `data_candidates`, `data_schedule`, `data_candidate_fold_metrics`, `data_candidate_repeat_summary`, `data_stage_timings`, `data_execution_provenance`, `list_prediction_cache` |
| `list_sjsdm_regularization_selection_artifact` | `sjsdm_regularization_selection` | `data_unit_selection`, `data_tier_selection`, `data_selection_for_fit` |
| `list_sjsdm_cv_prediction_artifact` | `sjsdm_cv_predictions` | `data_predictions`, `data_fold_diagnostics` |
| `list_sjsdm_cv_evaluation_artifact` | `sjsdm_cv_evaluation` | `list_pooled_evaluation`, `data_fold_metrics`, `list_fold_summaries`, `list_repeat_distributions`, `data_model_provenance` |
| `list_sjsdm_tier_tuning_artifact` | `sjsdm_tier_tuning` | `list_round_decisions`, `data_regularization_selection`, `data_source_candidate_loss`, `data_candidate_aggregation`, `data_selection_sensitivity` |
| `list_sjsdm_common_regularization_artifact` | `sjsdm_common_regularization` | `data_regularization_selection`, `data_candidate_aggregation`, `data_model_index`, `data_sensitivity_provenance` |

Mapped pipelines suffix these canonical base target names through their existing mapping mechanism. Schema identity is never encoded in a target-name suffix.

## Validation policy

- Unknown schema versions and artifact types fail closed.
- Payload names must match the registered names exactly; missing or additional payloads fail validation.
- Artifact-specific validators enforce table classes, column order and types, key uniqueness, list structure, status vocabulary, deterministic seed fields, and provenance values.
- V1 converters must first validate the complete frozen v1 input contract.
- Converted and native artifacts pass the same v2 envelope and payload validators.
- New pipelines publish no v1 aliases or downgrade artifacts.

## Scientific invariants

The v2 migration does not alter grouped holdout, feasibility fallback, fold-local processing, held-out MEM interpolation, candidates, tier weighting, metrics, seeds, scientific decision rules, or cumulative 8→4→2 tuning. Equivalence is tested on canonical payload content after excluding envelope-only metadata.

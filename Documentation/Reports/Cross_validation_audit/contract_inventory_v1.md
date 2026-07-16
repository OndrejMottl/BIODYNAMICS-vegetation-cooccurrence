# Cross-validation contract inventory (v1)

**Audit date:** 2026-07-14
**Issue:** #139
**Reference implementation:** `a8ead627` plus the initial Issue #139 tier-source stabilization

## Scientific invariants

| Contract | Required behavior | Evidence location | Audit status |
|---|---|---|---|
| Grouped holdout | Every core/plot location belongs wholly to one fold within a repeat; training and held-out locations are disjoint. | Assignment helpers, fold-context construction, fold preparation, grouped-assignment tests. | Covered. |
| Fold-local response processing | Constant-taxon filtering is learned only from the training response matrix; held-out taxa are aligned to the training-retained taxon set. | `prepare_model_fold_input()` and tests. | Covered, with an upstream-universe residual risk recorded in the findings narrative. |
| Fold-local abiotic scaling | Centers/scales are learned from aligned training predictors and applied unchanged to held-out predictors. | `prepare_model_fold_input()`, `apply_scale_attributes()`, and leakage tests. | Covered. |
| Fold-local spatial construction | MEMs are constructed only from training locations/samples; held-out locations are projected through the interpolation path and then transformed with training scale values. | `prepare_fold_spatial_predictors()` and interpolation tests. | Covered; fold-varying effective rank is retained in diagnostics and summarized explicitly in provenance. |
| Repeated assignment | Assignment is deterministic for the configured seed and repeats represent distinct intended origin perturbations. | Assignment functions and deterministic tests. | Covered, including complete origin coverage for even repeat counts. |
| Candidate comparison | Compatible candidates are evaluated on the same repeat/fold evidence and selected deterministically under the documented loss/weighting rule. | Tuning summaries, tier aggregation, selection tests. | Evidence completeness, deterministic scoring, and the pooled per-response loss estimand are stabilized. |
| Tuning loss estimand | Within each repeat and candidate, `negative_log_likelihood_per_response` equals total held-out negative log likelihood divided by total held-out response values across successful folds. Repartitioning identical held-out evidence does not change the result. | `summarise_sjsdm_tuning_candidates()` and unequal-fold/partition-invariance tests. | Covered; explicitly approved for the #138/#141 handoff. |
| Regularization domain | Every alpha elastic-net mixing value is finite in `[0, 1]`; every lambda strength is finite and non-negative on candidate and direct/final-fit paths. | Candidate construction and `fit_jsdm_model()` argument tests. | Covered. |
| Tier weighting | Primary tier selection weights source IDs equally; sample-weighted selection is sensitivity output only. | `aggregate_sjsdm_tuning_by_tier()` and tier artifact tests. | Covered. |
| Predictive evaluation | Selected-candidate probabilities are out-of-fold. The historical evaluator pools within repeat/taxon for compatibility; the fold-local evaluator scores repeat/fold/taxon groups before macro or observation-weighted aggregation. Fitted evaluation remains separate. | Selected-fold runner, pooled and fold-local evaluators, pipeline targets, and tests. | Covered, including exact prediction/scoring error statuses, paired null improvements, coverage, and repeat distributions. |
| Reproducibility | Assignment, fit, and score seeds derive from the configured seed and are recorded without depending on ambient RNG state. | Assignment, tuning runner, joint scorer, and provenance tests. | Covered for assignment, fitting, and stochastic tuning scores. |
| External-store completeness | Tier artifacts may be created only from readable summaries for every requested store-resolution pair, and external content must be reread on each tier run. | `collect_sjsdm_tuning_summaries()`, `pipeline_sjsdm_tier_tuning.R`, and Issue #139 regression tests. | Stabilized with a fail-closed policy in the initial slice. |
| Spatial runner failure policy | Unit tuning-summary production is fail-fast before tier aggregation; post-selection full-unit completion may continue only while retaining one explicit outcome for every requested unit. | Six spatial runners, `run_pipeline_units_with_status()`, and orchestration contract tests. | Covered with `ok`/`error` status and error-message capture. |
| Cross-tier sensitivity readiness | Common-regularization sensitivity may start only when every enabled tier's configured representative store exists; otherwise the local runner must complete with actionable skipped evidence. | `run_sjsdm_cross_tier_sensitivity()`, both local spatial runners, and readiness tests. | Covered with per-tier store and overall sensitivity statuses. |

## Public target-name contract

| Stage | Stable target names |
|---|---|
| Shared pre-resolution assignment | `config_cross_validation_shared`, `data_cross_validation_sample_ids_shared`, `data_cross_validation_locations_shared`, `data_cross_validation_fold_resolution_shared`, `data_cross_validation_grid_candidates_shared`, `data_cross_validation_grid_calibration_shared`, `data_cross_validation_assignments_shared` |
| Branch assignment and feasibility | `data_cross_validation_locations`, `data_cross_validation_fold_resolution`, `data_cross_validation_assignments_initial`, `data_cross_validation_partition_diagnostics_initial`, `data_cross_validation_assignments`, `data_cross_validation_partition_diagnostics`, `data_cross_validation_feasibility` |
| Unit tuning | `data_sjsdm_regularization_candidates`, `data_sjsdm_model_context`, `data_sjsdm_tuning_candidates`, `data_sjsdm_tuning_summary`, `data_sjsdm_selected_regularization_unit` |
| Tier artifact consumption | `data_sjsdm_tier_regularization_artifact`, `model_regularization_for_fit` |
| Selected OOF output | `list_sjsdm_selected_fold_predictions`, `data_sjsdm_out_of_fold_predictions`, `data_sjsdm_out_of_fold_diagnostics` |
| Predictive evaluation/provenance | `data_sjsdm_model_provenance`, `model_evaluation_cross_validated`, `data_sjsdm_fold_local_metrics`, `list_sjsdm_fold_metric_summaries`, `list_sjsdm_metric_repeat_distributions` |
| Tier store | `data_sjsdm_tier_tuning_summaries`, `sjsdm_tier_artifact_created_at`, `list_sjsdm_tier_tuning_artifacts`, `data_sjsdm_tier_regularization_artifacts`, `data_sjsdm_tier_source_candidate_loss`, `data_sjsdm_tier_candidate_aggregation`, `data_sjsdm_tier_selection_sensitivity` |
| Common sensitivity store | `data_sjsdm_common_profile_context`, `data_sjsdm_common_tuning_summaries`, `data_sjsdm_common_regularization_artifacts`, `data_sjsdm_common_candidate_aggregation`, `data_sjsdm_common_model_index`, sensitivity result/model/ANOVA/provenance/decomposition targets |

Mapped resolution pipelines suffix branch targets by resolution while preserving these base names as the public naming template.

## Artifact schema contracts

| Artifact | Required schema/content |
|---|---|
| Fold assignment | Repeat/fold identifiers, location identifier, list-column row indices, sample/location counts as applicable, strategy, grid-cell identity when applicable, and assignment source. Assignment sources distinguish direct/shared/fallback/no-holdout behavior. |
| Fold-level tuning output | Repeat/fold/candidate keys, six regularization parameters, distinct deterministic fit and score seeds, fold counts, metrics, structured status/error fields, CV strategy, and regularization source. |
| Unit tuning summary | Model context, source/repeat/candidate keys, six regularization parameters, response count, loss and probability metrics, fit/status fields, and candidate-table identity. Keys must be unique for source/repeat/candidate. |
| Tier regularization artifact | One row with `artifact_schema_version = "1.0.0"`, creation time, tier/context/hash, selected candidate and six parameters, `regularization_source = "tier_pooled"`, equal-ID weighting metadata, source count, and source-ID list. |
| OOF predictions | `repeat_id`, `fold_id`, `row_index`, `location_id`, `dataset_name`, `age`, `taxon`, `observed`, `predicted_probability`, `null_probability`, and `prediction_status`; repeat/row/taxon keys are unique and cover the assignment universe. |
| OOF diagnostics | Repeat/fold/candidate and fit seed, train/test/taxon/MEM counts, fit status/error message, CV strategy, and regularization source. |
| Predictive evaluation | Named list of taxon metrics and community summaries. Taxon metrics contain repeat/taxon/metric, estimate/status, observation/class counts, and prevalence. Community output contains repeat/metric/statistic, estimate, evaluable-taxon count, and status. |
| Fold-local evaluation | Long table keyed by repeat/fold/taxon, prediction source, and metric. It contains estimate/status, observation/class counts, and prevalence for Tjur R2, AUC, log loss, Brier score, calibration intercept, and calibration slope. |
| Fold-metric summaries | Named list of source summaries and paired improvements. Both retain fold-macro and observation-weighted estimates plus fold/taxon/observation/class coverage; positive paired estimates always favor the model. |
| Repeat-metric distributions | Named list of source and paired repeat distributions with mean, median, standard deviation, empirical 95 percent repeat bounds, repeat counts, and fold-taxon coverage. Paired output also records the proportion of positive repeats. |
| Model provenance | Selected candidate/context/source/status, feasibility counts/strategy/status, repeat/fold success counts, retained-taxon count, and effective MEM scalar/minimum/maximum/status. It also records fitting device, OOF prediction source, repeat/fold/taxon estimand, fold-macro and observation-weighted aggregation methods, and schema version `sjsdm_fold_local_cv_v1`. The legacy MEM scalar is populated only when effective rank is constant across folds. |

## Critical status vocabulary

| Domain | Status values/meaning |
|---|---|
| Strategy | `spatially_stratified_group_kfold`, `leave_one_location_out`, or `none`. |
| Assignment source | Shared pre-resolution reuse, branch fallback, or branch no-holdout are explicit; callers must not infer source from missing grid IDs alone. |
| Fold execution | `ok`, `preparation_error`, `fit_error`, `prediction_error`, and `scoring_error` preserve the failed stage and an error message. |
| Prediction rows | `ok` plus explicit non-predictive states such as preparation/fit/prediction errors, unaligned held-out rows, or taxa constant in training. |
| Metrics | `ok`, incomplete-prediction status, metric-specific one-class/undefined status, or no-evaluable-taxa status. Negative valid Tjur R2 remains an estimate, not an error status. |
| Tier source read | Initial Issue #139 policy is fail-closed: any unreadable requested store-resolution target aborts tier collection with the target and store in the error. |
| Post-selection unit run | `ok` records completion; `error` retains the captured error message. Every requested unit has exactly one row. |
| Common-sensitivity readiness | Representative stores are `ready`, `missing`, or `disabled`; profile sensitivity states are `completed`, `skipped_missing_store`, or `skipped_disabled`. |

## Store and provenance rules

- Unit, tier, and common-sensitivity stores remain physically isolated.
- Stable external store paths are not sufficient invalidation tokens; reads must be always-cued or depend on explicit content metadata/hashes.
- Artifact creation time cannot substitute for refreshing upstream external content.
- Candidate-table hash and model context must match before evidence is pooled.
- Public artifact schemas remain unchanged unless an approved migration includes compatibility tests.

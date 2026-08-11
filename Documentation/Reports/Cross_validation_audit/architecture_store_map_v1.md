# Cross-validation architecture and store map (v1)

**Audit date:** 2026-07-14 **Issue:** #139 **Reference implementation:** `a8ead627`

## Execution architecture

```text
raw community + sample metadata + abiotic/spatial inputs
  -> grouped location table
  -> fold-count feasibility and assignment strategy
  -> deterministic grouped fold assignments
  -> fold-local response filtering and predictor preparation
       -> training-only abiotic scaling
       -> training-only MEM construction
       -> held-out MEM interpolation
       -> training-only spatial scaling applied to held-out MEMs
  -> candidate fit per repeat/fold
  -> held-out joint likelihood and probability metrics
  -> unit tuning summary
  -> isolated tier-tuning store pools compatible unit summaries
  -> selected tier regularization artifact
  -> unit store reloads the tier artifact
  -> selected-candidate fit and prediction per repeat/fold
  -> aligned out-of-fold prediction and diagnostic artifacts
  -> predictive taxon/community evaluation and model provenance
  -> full-data final fit using the selected regularization
```

## Direct and shared assignment routes

| Route | Pipelines | Assignment ownership | Branch behavior |
|---|---|---|---|
| Direct | `pipeline_paleo_core.R`, `pipeline_paleo_temporal.R` | `pipe_segment_model_cross_validation.R` builds locations, calibrates the grid, assigns folds, fits candidates, and evaluates selected OOF predictions inside each branch. | Each branch owns its complete assignment and CV graph. |
| Shared pre-resolution | `pipeline_paleo_spatial_resolution.R`, `pipeline_modern_spatial_resolution.R`, and their test variants | `pipe_segment_model_cross_validation_shared.R` constructs assignments from the common sample universe before resolution branching. | `pipe_segment_model_cross_validation_from_shared.R` reuses shared assignments when branch coverage and balance remain valid, otherwise creates a branch-local fallback while preserving the public branch target names. |

## Public unit-store target flow

The direct and from-shared routes expose the same public branch contract after assignment construction.

| Stage | Public targets |
|---|---|
| Grouping and assignment | `data_cross_validation_locations`, `data_cross_validation_fold_resolution`, `data_cross_validation_assignments_initial`, `data_cross_validation_partition_diagnostics_initial`, `data_cross_validation_assignments`, `data_cross_validation_partition_diagnostics`, `data_cross_validation_feasibility` |
| Candidate definition and tuning | `data_sjsdm_regularization_candidates`, `data_sjsdm_model_context`, `data_sjsdm_tuning_candidates`, `data_sjsdm_tuning_summary`, `data_sjsdm_selected_regularization_unit` |
| Tier selection | `data_sjsdm_tier_regularization_artifact`, `model_regularization_for_fit` |
| Selected OOF execution | `list_sjsdm_selected_fold_predictions`, `data_sjsdm_out_of_fold_predictions`, `data_sjsdm_out_of_fold_diagnostics`, `data_sjsdm_fold_local_metrics`, `list_sjsdm_fold_metric_summaries`, `list_sjsdm_metric_repeat_distributions` |
| Evaluation and provenance | `data_sjsdm_model_provenance`, `model_evaluation_cross_validated` |

The direct route additionally exposes `data_cross_validation_grid_candidates` and `data_cross_validation_grid_calibration`. The shared route exposes the corresponding pre-branch targets with a `_shared` suffix.

## Store boundaries and orchestration

| Store | Path pattern | Reads | Writes | Invalidation boundary |
|---|---|---|---|---|
| Unit model store | `<configured target_store>/<optional unit suffix>/<model pipeline>` | Project data/configuration and, during completion, the tier artifact store | Unit tuning summaries, assignments, selected OOF artifacts, evaluation, provenance, and final model outputs | Managed by the unit pipeline; spatial units remain isolated. |
| Tier tuning store | `<configured target_store>/pipeline_sjsdm_tier_tuning` | Compact `data_sjsdm_tuning_summary_<resolution>` targets from all compatible unit stores | Tier artifacts, source-level losses, candidate aggregation, and weighting sensitivity | External unit stores are not native target dependencies and must be explicitly re-read or content-hashed. Finding CV-001 records a missing invalidation edge. |
| Common regularization sensitivity store | `<configured target_store>/pipeline_sjsdm_common_regularization_sensitivity` | Representative unit tuning summaries, model inputs, formulas, configuration, provenance, and common artifacts | Common-candidate aggregation, sensitivity models, ANOVA, decomposition, and provenance | Summary collection is always-cued; the always-changing artifact creation timestamp currently propagates into the sensitivity refit dependency. |

## Runner sequence

1. Run each unit/model pipeline only through its tuning-summary targets.
2. Run `pipeline_sjsdm_tier_tuning.R` to pool compatible evidence and write the tier artifact.
3. Resume each unit/model pipeline so it loads the tier artifact, produces selected-candidate OOF outputs, evaluation/provenance, and completes the final fit.
4. Where configured, run common-regularization sensitivity only after the representative spatial unit stores and tier artifacts exist.

This sequencing is visible in the paleo, modern, and temporal orchestration runners and is part of the production contract.

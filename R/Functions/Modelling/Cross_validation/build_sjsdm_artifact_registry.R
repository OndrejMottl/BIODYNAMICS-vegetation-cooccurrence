#' @title Build the sjSDM Artifact Registry
#' @description
#' Defines every supported cross-validation v2 artifact type and its exact
#' ordered payload names.
#' @return
#' Named list mapping artifact types to character vectors of payload names.
#' @examples
#' build_sjsdm_artifact_registry()
#' @export
build_sjsdm_artifact_registry <- function() {
  list_registry <-
    base::list(
      cross_validation_shared_design = base::c(
        "data_sample_ids",
        "data_locations",
        "data_fold_resolution",
        "data_grid_candidates",
        "data_grid_calibration",
        "data_assignments",
        "data_assignment_provenance"
      ),
      cross_validation_design = base::c(
        "data_locations",
        "data_fold_resolution",
        "data_assignments_initial",
        "data_partition_diagnostics_initial",
        "data_assignments",
        "data_partition_diagnostics",
        "data_feasibility",
        "data_route_provenance"
      ),
      sjsdm_cv_tuning = base::c(
        "data_candidates",
        "data_schedule",
        "data_candidate_fold_metrics",
        "data_candidate_repeat_summary",
        "data_stage_timings",
        "data_execution_provenance",
        "list_prediction_cache"
      ),
      sjsdm_regularization_selection = base::c(
        "data_unit_selection",
        "data_tier_selection",
        "data_selection_for_fit"
      ),
      sjsdm_cv_predictions = base::c(
        "data_predictions",
        "data_fold_diagnostics"
      ),
      sjsdm_cv_evaluation = base::c(
        "list_pooled_evaluation",
        "data_fold_metrics",
        "list_fold_summaries",
        "list_repeat_distributions",
        "data_model_provenance"
      ),
      sjsdm_tier_tuning = base::c(
        "list_round_decisions",
        "data_regularization_selection",
        "data_source_candidate_loss",
        "data_candidate_aggregation",
        "data_selection_sensitivity"
      ),
      sjsdm_common_regularization = base::c(
        "data_regularization_selection",
        "data_candidate_aggregation",
        "data_model_index",
        "data_sensitivity_provenance"
      )
    )

  return(list_registry)
}

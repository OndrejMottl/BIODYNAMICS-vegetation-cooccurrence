#' @title Validate the cross validation design Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_cross_validation_design_payload <- function(payload = NULL) {
  vec_location_columns <-
    base::c(
      "location_id",
      "coord_x_km",
      "coord_y_km",
      "n_samples",
      "row_indices"
    )

  vec_resolution_columns <-
    base::c(
      "n_locations",
      "default_folds",
      "effective_folds",
      "min_train_locations",
      "min_training_locations_actual",
      "cv_strategy",
      "cv_feasibility_status"
    )

  vec_assignment_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "location_id",
      "grid_cell_id",
      "n_samples",
      "row_indices",
      "cv_strategy",
      "assignment_source"
    )

  vec_diagnostic_columns <-
    base::c(
      "cv_strategy",
      "repeat_id",
      "effective_folds",
      "fold_id",
      "n_train_locations",
      "n_train_samples",
      "n_train_taxa",
      "n_train_mem_locations"
    )

  vec_feasibility_columns <-
    base::c(
      "n_locations",
      "n_samples",
      "n_taxa",
      "n_mem_locations",
      "full_model_feasible",
      "grouped_kfold_feasible",
      "leave_one_location_out_feasible",
      "cv_strategy",
      "effective_folds",
      "cv_feasibility_status"
    )

  vec_route_columns <-
    base::c(
      "assignment_route",
      "assignment_source",
      "assignment_seed"
    )

  vec_cv_strategies <-
    base::c(
      "full_model",
      "spatially_stratified_group_kfold",
      "leave_one_location_out",
      "none"
    )

  vec_feasibility_statuses <-
    base::c(
      "grouped_kfold_feasible",
      "leave_one_location_out_required",
      "tier_pooled_regularization_required",
      "full_model_infeasible"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "cross_validation_design",
      payload = payload,
      list_table_contracts = base::list(
        data_locations = base::list(
          columns = vec_location_columns,
          types = stats::setNames(
            base::c(
              "character",
              "double",
              "double",
              "integer",
              "list"
            ),
            vec_location_columns
          ),
          keys = "location_id"
        ),
        data_fold_resolution = base::list(
          columns = vec_resolution_columns,
          types = stats::setNames(
            base::c(base::rep("integer", 5L), base::rep("character", 2L)),
            vec_resolution_columns
          ),
          n_rows = 1L,
          statuses = base::list(
            cv_strategy = vec_cv_strategies,
            cv_feasibility_status = vec_feasibility_statuses
          )
        ),
        data_assignments_initial = base::list(
          columns = vec_assignment_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "integer",
              "character",
              "character",
              "integer",
              "list",
              "character",
              "character"
            ),
            vec_assignment_columns
          ),
          keys = base::c("repeat_id", "location_id"),
          statuses = base::list(cv_strategy = vec_cv_strategies)
        ),
        data_partition_diagnostics_initial = base::list(
          columns = vec_diagnostic_columns,
          types = stats::setNames(
            base::c("character", base::rep("integer", 7L)),
            vec_diagnostic_columns
          ),
          keys = base::c("cv_strategy", "repeat_id", "fold_id"),
          statuses = base::list(cv_strategy = vec_cv_strategies)
        ),
        data_assignments = base::list(
          columns = vec_assignment_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "integer",
              "character",
              "character",
              "integer",
              "list",
              "character",
              "character"
            ),
            vec_assignment_columns
          ),
          keys = base::c("repeat_id", "location_id"),
          statuses = base::list(cv_strategy = vec_cv_strategies)
        ),
        data_partition_diagnostics = base::list(
          columns = vec_diagnostic_columns,
          types = stats::setNames(
            base::c("character", base::rep("integer", 7L)),
            vec_diagnostic_columns
          ),
          keys = base::c("cv_strategy", "repeat_id", "fold_id"),
          statuses = base::list(cv_strategy = vec_cv_strategies)
        ),
        data_feasibility = base::list(
          columns = vec_feasibility_columns,
          types = stats::setNames(
            base::c(
              base::rep("integer", 4L),
              base::rep("logical", 3L),
              "character",
              "integer",
              "character"
            ),
            vec_feasibility_columns
          ),
          n_rows = 1L,
          statuses = base::list(
            cv_strategy = vec_cv_strategies,
            cv_feasibility_status = vec_feasibility_statuses
          )
        ),
        data_route_provenance = base::list(
          columns = vec_route_columns,
          types = stats::setNames(
            base::c("character", "character", "integer"),
            vec_route_columns
          ),
          n_rows = 1L,
          statuses = base::list(
            assignment_route = base::c(
              "direct",
              "shared_assignment_branch"
            )
          )
        )
      )
    )

  return(res)
}

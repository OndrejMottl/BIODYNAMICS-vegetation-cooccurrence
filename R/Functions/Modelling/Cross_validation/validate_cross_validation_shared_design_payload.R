#' @title Validate the cross validation shared design Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_cross_validation_shared_design_payload <- function(payload = NULL) {
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

  vec_candidate_columns <-
    base::c(
      "candidate_id",
      "grid_cell_size_km",
      "baseline_grid_cell_size_km",
      "grid_size_multiplier",
      "n_locations",
      "extent_x_km",
      "extent_y_km",
      "extent_area_km2",
      "target_locations_per_cell"
    )

  vec_calibration_columns <-
    base::c(
      "grid_cell_size_km",
      "mean_occupied_cells",
      "minimum_locations_per_cell",
      "lower_quantile_locations_per_cell",
      "median_locations_per_cell",
      "occupancy_criterion",
      "occupancy_value",
      "target_locations_per_cell",
      "maximum_fold_location_difference",
      "maximum_fold_sample_difference",
      "eligible",
      "selected",
      "selection_status"
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

  vec_cv_strategies <-
    base::c(
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
      artifact_type = "cross_validation_shared_design",
      payload = payload,
      list_table_contracts = base::list(
        data_sample_ids = base::list(
          columns = base::c("dataset_name", "age"),
          types = base::c(
            dataset_name = "character",
            age = "double"
          ),
          keys = base::c("dataset_name", "age")
        ),
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
        data_grid_candidates = base::list(
          columns = vec_candidate_columns,
          types = stats::setNames(
            base::c(
              "character",
              base::rep("double", 3L),
              "integer",
              base::rep("double", 3L),
              "integer"
            ),
            vec_candidate_columns
          ),
          keys = "candidate_id"
        ),
        data_grid_calibration = base::list(
          columns = vec_calibration_columns,
          types = stats::setNames(
            base::c(
              base::rep("double", 2L),
              "integer",
              base::rep("double", 2L),
              "character",
              "double",
              base::rep("integer", 3L),
              base::rep("logical", 2L),
              "character"
            ),
            vec_calibration_columns
          ),
          keys = "grid_cell_size_km",
          statuses = base::list(
            occupancy_criterion = base::c(
              "minimum",
              "lower_quantile",
              "median"
            ),
            selection_status = base::c(
              "selected",
              "no_eligible_grid"
            )
          )
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
        data_assignment_provenance = base::list(
          columns = base::c("assignment_source", "assignment_seed"),
          types = base::c(
            assignment_source = "character",
            assignment_seed = "integer"
          ),
          n_rows = 1L,
          statuses = base::list(
            assignment_source = "shared_pre_resolution"
          )
        )
      )
    )

  return(res)
}

testthat::test_that(
  base::paste(
    "convert_v1_cross_validation_design_artifact() upgrades",
    "the frozen v1 fixture"
  ),
  {
    data_locations <-
      tibble::tibble(
        location_id = base::character(),
        coord_x_km = base::numeric(),
        coord_y_km = base::numeric(),
        n_samples = base::integer(),
        row_indices = base::list()
      )

    data_assignments <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        location_id = base::character(),
        grid_cell_id = base::character(),
        n_samples = base::integer(),
        row_indices = base::list(),
        cv_strategy = base::character(),
        assignment_source = base::character()
      )

    data_diagnostics <-
      tibble::tibble(
        cv_strategy = base::character(),
        repeat_id = base::integer(),
        effective_folds = base::integer(),
        fold_id = base::integer(),
        n_train_locations = base::integer(),
        n_train_samples = base::integer(),
        n_train_taxa = base::integer(),
        n_train_mem_locations = base::integer()
      )

    payload <-
      base::list(
        data_locations = data_locations,
        data_fold_resolution = tibble::tibble(
          n_locations = 0L,
          default_folds = 5L,
          effective_folds = 0L,
          min_train_locations = 2L,
          min_training_locations_actual = 0L,
          cv_strategy = "none",
          cv_feasibility_status = "full_model_infeasible"
        ),
        data_assignments_initial = data_assignments,
        data_partition_diagnostics_initial = data_diagnostics,
        data_assignments = data_assignments,
        data_partition_diagnostics = data_diagnostics,
        data_feasibility = tibble::tibble(
          n_locations = 0L,
          n_samples = 0L,
          n_taxa = 0L,
          n_mem_locations = 0L,
          full_model_feasible = FALSE,
          grouped_kfold_feasible = FALSE,
          leave_one_location_out_feasible = FALSE,
          cv_strategy = "none",
          effective_folds = 0L,
          cv_feasibility_status = "full_model_infeasible"
        ),
        data_route_provenance = tibble::tibble(
          assignment_route = "direct",
          assignment_source = "branch_no_holdout",
          assignment_seed = NA_integer_
        )
      )

    res <-
      convert_v1_cross_validation_design_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(
      res[["artifact_type"]],
      "cross_validation_design"
    )
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )
  }
)

testthat::test_that(
  paste(
    "convert_v1_cross_validation_shared_design_artifact() upgrades",
    "the frozen v1 fixture"
  ),
  {
    payload <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = "site_a",
          age = 0
        ),
        data_locations = tibble::tibble(
          location_id = "site_a",
          coord_x_km = 1,
          coord_y_km = 2,
          n_samples = 1L,
          row_indices = base::list(1L)
        ),
        data_fold_resolution = tibble::tibble(
          n_locations = 1L,
          default_folds = 5L,
          effective_folds = 1L,
          min_train_locations = 1L,
          min_training_locations_actual = 1L,
          cv_strategy = "leave_one_location_out",
          cv_feasibility_status = "leave_one_location_out_required"
        ),
        data_grid_candidates = tibble::tibble(
          candidate_id = "grid_001",
          grid_cell_size_km = 10,
          baseline_grid_cell_size_km = 10,
          grid_size_multiplier = 1,
          n_locations = 1L,
          extent_x_km = 0,
          extent_y_km = 0,
          extent_area_km2 = 0,
          target_locations_per_cell = 1L
        ),
        data_grid_calibration = tibble::tibble(
          grid_cell_size_km = 10,
          mean_occupied_cells = 1,
          minimum_locations_per_cell = 1L,
          lower_quantile_locations_per_cell = 1,
          median_locations_per_cell = 1,
          occupancy_criterion = "minimum",
          occupancy_value = 1,
          target_locations_per_cell = 1L,
          maximum_fold_location_difference = 0L,
          maximum_fold_sample_difference = 0L,
          eligible = TRUE,
          selected = TRUE,
          selection_status = "selected"
        ),
        data_assignments = tibble::tibble(
          repeat_id = 1L,
          fold_id = 1L,
          location_id = "site_a",
          grid_cell_id = NA_character_,
          n_samples = 1L,
          row_indices = base::list(1L),
          cv_strategy = "leave_one_location_out",
          assignment_source = "shared_pre_resolution"
        ),
        data_assignment_provenance = tibble::tibble(
          assignment_source = "shared_pre_resolution",
          assignment_seed = 900723L
        )
      )

    res <-
      convert_v1_cross_validation_shared_design_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(
      res[["artifact_type"]],
      "cross_validation_shared_design"
    )
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )
  }
)

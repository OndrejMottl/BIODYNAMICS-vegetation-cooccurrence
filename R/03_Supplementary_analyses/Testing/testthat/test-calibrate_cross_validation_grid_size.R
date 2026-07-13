testthat::test_that(
  "calibrate_cross_validation_grid_size() selects finest grid",
  {
    data_locations <-
      tibble::tibble(
        location_id = stringr::str_c("plot_", base::seq_len(12L)),
        coord_x_km = base::c(
          0, 1, 2,
          10, 11, 12,
          20, 21, 22,
          30, 31, 32
        ),
        coord_y_km = base::rep(0, 12L),
        n_samples = base::rep(1L, 12L),
        row_indices = base::as.list(base::seq_len(12L))
      )

    data_calibration <-
      calibrate_cross_validation_grid_size(
        data_locations = data_locations,
        candidate_grid_cell_sizes_km = base::c(1, 10, 100),
        n_folds = 3L,
        n_repeats = 1L,
        occupancy_criterion = "median",
        target_locations_per_cell = 3,
        seed = 900723L
      )

    testthat::expect_named(
      data_calibration,
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
    )
    testthat::expect_equal(
      data_calibration |>
        dplyr::filter(selected) |>
        dplyr::pull(grid_cell_size_km),
      10
    )
    testthat::expect_false(
      data_calibration |>
        dplyr::filter(grid_cell_size_km == 1) |>
        dplyr::pull(eligible)
    )
    testthat::expect_equal(
      base::sum(dplyr::pull(data_calibration, selected)),
      1L
    )
  }
)

testthat::test_that(
  "calibrate_cross_validation_grid_size() reports no eligible grid",
  {
    data_locations <-
      tibble::tibble(
        location_id = stringr::str_c("plot_", base::seq_len(6L)),
        coord_x_km = base::seq(0, 25, by = 5),
        coord_y_km = base::rep(0, 6L),
        n_samples = base::rep(1L, 6L),
        row_indices = base::as.list(base::seq_len(6L))
      )

    data_calibration <-
      calibrate_cross_validation_grid_size(
        data_locations = data_locations,
        candidate_grid_cell_sizes_km = base::c(5, 10),
        n_folds = 3L,
        target_locations_per_cell = 20
      )

    testthat::expect_false(
      base::any(dplyr::pull(data_calibration, selected))
    )
    testthat::expect_true(
      base::all(
        dplyr::pull(data_calibration, selection_status) ==
          "no_eligible_grid"
      )
    )
  }
)

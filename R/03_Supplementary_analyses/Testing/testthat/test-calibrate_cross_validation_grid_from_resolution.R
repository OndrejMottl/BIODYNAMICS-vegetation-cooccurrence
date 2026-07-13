testthat::test_that(
  "calibrate_cross_validation_grid_from_resolution() dispatches grouped CV",
  {
    data_locations <-
      tibble::tibble(
        location_id = stringr::str_c("plot_", base::seq_len(12L)),
        coord_x_km = base::c(
          0, 1, 2, 10, 11, 12, 20, 21, 22, 30, 31, 32
        ),
        coord_y_km = base::rep(0, 12L),
        n_samples = base::rep(1L, 12L),
        row_indices = base::as.list(base::seq_len(12L))
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 12L,
        min_train_locations = 5L,
        default_folds = 3L
      )

    data_calibration <-
      calibrate_cross_validation_grid_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        candidate_grid_cell_sizes_km = base::c(1, 10, 100),
        target_locations_per_cell = 3
      )

    testthat::expect_equal(
      data_calibration |>
        dplyr::filter(.data[["selected"]]) |>
        dplyr::pull("grid_cell_size_km"),
      10
    )
  }
)

testthat::test_that(
  "calibrate_cross_validation_grid_from_resolution() skips gridless CV",
  {
    data_locations <-
      tibble::tibble(
        location_id = letters[1:6],
        coord_x_km = base::seq_len(6L),
        coord_y_km = base::seq_len(6L),
        n_samples = base::rep(1L, 6L),
        row_indices = base::as.list(base::seq_len(6L))
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 6L,
        min_train_locations = 5L
      )

    data_calibration <-
      calibrate_cross_validation_grid_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        candidate_grid_cell_sizes_km = base::c(1, 10)
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
    testthat::expect_equal(base::nrow(data_calibration), 0L)
  }
)

testthat::test_that(
  "calibrate_cross_validation_grid_from_resolution() validates resolution",
  {
    testthat::expect_error(
      calibrate_cross_validation_grid_from_resolution(
        data_locations = tibble::tibble(),
        data_fold_resolution = tibble::tibble(),
        candidate_grid_cell_sizes_km = 1
      ),
      "exactly one row"
    )
  }
)

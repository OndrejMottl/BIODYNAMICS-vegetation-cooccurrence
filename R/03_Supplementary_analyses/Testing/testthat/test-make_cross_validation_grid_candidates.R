testthat::test_that(
  "make_cross_validation_grid_candidates() derives widths from density",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::c("a", "b", "c", "d"),
        coord_x_km = base::c(0, 0, 10, 10),
        coord_y_km = base::c(0, 10, 0, 10),
        n_samples = base::rep(1L, 4L),
        row_indices = base::as.list(base::seq_len(4L))
      )

    data_candidates <-
      make_cross_validation_grid_candidates(
        data_locations = data_locations,
        target_locations_per_cell = 1,
        grid_size_multipliers = base::c(0.5, 1, 2)
      )

    testthat::expect_named(
      data_candidates,
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
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, baseline_grid_cell_size_km),
      base::rep(5, 3L)
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, grid_cell_size_km),
      base::c(2.5, 5, 10)
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, candidate_id),
      base::c("grid_001", "grid_002", "grid_003")
    )
  }
)

testthat::test_that(
  "make_cross_validation_grid_candidates() rejects zero-area extent",
  {
    data_locations <-
      tibble::tibble(
        coord_x_km = base::c(1, 1, 1),
        coord_y_km = base::c(0, 1, 2)
      )

    testthat::expect_error(
      make_cross_validation_grid_candidates(data_locations),
      "positive extent"
    )
  }
)

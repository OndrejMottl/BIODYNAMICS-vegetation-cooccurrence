testthat::test_that(
  "make_cross_validation_grid_candidates_from_resolution() dispatches",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::letters[1:8],
        coord_x_km = base::c(0, 1, 2, 3, 10, 11, 12, 13),
        coord_y_km = base::c(0, 1, 2, 3, 0, 1, 2, 3),
        n_samples = base::rep(1L, 8L),
        row_indices = base::as.list(base::seq_len(8L))
      )
    data_grouped_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 8L,
        min_train_locations = 5L
      )
    data_gridless_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 6L,
        min_train_locations = 5L
      )

    data_grouped_candidates <-
      make_cross_validation_grid_candidates_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_grouped_resolution,
        target_locations_per_cell = 5,
        grid_size_multipliers = base::c(0.5, 1)
      )
    data_gridless_candidates <-
      make_cross_validation_grid_candidates_from_resolution(
        data_locations = data_locations[1:6, ],
        data_fold_resolution = data_gridless_resolution
      )

    testthat::expect_equal(base::nrow(data_grouped_candidates), 2L)
    testthat::expect_equal(base::nrow(data_gridless_candidates), 0L)
    testthat::expect_named(
      data_gridless_candidates,
      base::names(data_grouped_candidates)
    )
  }
)

testthat::test_that(
  "make_cross_validation_grid_candidates_from_resolution() validates strategy",
  {
    testthat::expect_error(
      make_cross_validation_grid_candidates_from_resolution(
        data_locations = tibble::tibble(),
        data_fold_resolution = tibble::tibble(
          cv_strategy = "unsupported"
        )
      ),
      "not supported"
    )
  }
)

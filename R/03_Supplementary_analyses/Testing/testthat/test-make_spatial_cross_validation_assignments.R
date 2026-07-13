testthat::test_that(
  "make_spatial_cross_validation_assignments() preserves locations",
  {
    data_locations <-
      tibble::tibble(
        location_id = stringr::str_c("core_", base::seq_len(8L)),
        coord_x_km = base::c(0, 1, 5, 6, 10, 11, 15, 16),
        coord_y_km = base::c(0, 1, 0, 1, 0, 1, 0, 1),
        n_samples = base::c(2L, 1L, 3L, 1L, 2L, 1L, 2L, 1L),
        row_indices = base::list(
          base::c(1L, 2L),
          3L,
          base::c(4L, 5L, 6L),
          7L,
          base::c(8L, 9L),
          10L,
          base::c(11L, 12L),
          13L
        )
      )

    data_assignments <-
      make_spatial_cross_validation_assignments(
        data_locations = data_locations,
        n_folds = 3L,
        n_repeats = 2L,
        grid_cell_size_km = 5,
        seed = 900723L
      )

    testthat::expect_named(
      data_assignments,
      base::c(
        "repeat_id",
        "fold_id",
        "location_id",
        "grid_cell_id",
        "n_samples",
        "row_indices"
      )
    )
    testthat::expect_equal(base::nrow(data_assignments), 16L)

    data_repeat_counts <-
      data_assignments |>
      dplyr::count(repeat_id, location_id)

    testthat::expect_true(
      base::all(dplyr::pull(data_repeat_counts, n) == 1L)
    )

    data_fold_balance <-
      data_assignments |>
      dplyr::count(repeat_id, fold_id) |>
      dplyr::group_by(repeat_id) |>
      dplyr::summarise(
        difference = base::max(n) - base::min(n),
        .groups = "drop"
      )

    testthat::expect_true(
      base::all(dplyr::pull(data_fold_balance, difference) <= 1L)
    )

    data_cell_fold_counts <-
      data_assignments |>
      dplyr::count(repeat_id, grid_cell_id, fold_id) |>
      dplyr::group_by(repeat_id, grid_cell_id) |>
      dplyr::summarise(
        maximum = base::max(n),
        .groups = "drop"
      )

    testthat::expect_true(
      base::all(dplyr::pull(data_cell_fold_counts, maximum) == 1L)
    )
  }
)

testthat::test_that(
  "make_spatial_cross_validation_assignments() is deterministic",
  {
    data_locations <-
      tibble::tibble(
        location_id = stringr::str_c("plot_", base::seq_len(6L)),
        coord_x_km = base::c(0, 4, 6, 10, 14, 16),
        coord_y_km = base::rep(0, 6L),
        n_samples = base::rep(1L, 6L),
        row_indices = base::as.list(base::seq_len(6L))
      )

    base::set.seed(900723L)
    expected_next_random <-
      stats::runif(1L)

    base::set.seed(900723L)
    data_first <-
      make_spatial_cross_validation_assignments(
        data_locations = data_locations,
        n_folds = 3L,
        n_repeats = 2L,
        grid_cell_size_km = 5,
        seed = 123L
      )
    actual_next_random <-
      stats::runif(1L)

    data_second <-
      make_spatial_cross_validation_assignments(
        data_locations = data_locations,
        n_folds = 3L,
        n_repeats = 2L,
        grid_cell_size_km = 5,
        seed = 123L
      )

    testthat::expect_equal(data_first, data_second)
    testthat::expect_equal(actual_next_random, expected_next_random)

    data_grid_by_repeat <-
      data_first |>
      dplyr::select(repeat_id, location_id, grid_cell_id) |>
      tidyr::pivot_wider(
        names_from = repeat_id,
        values_from = grid_cell_id
      )

    testthat::expect_true(
      base::any(
        data_grid_by_repeat[["1"]] != data_grid_by_repeat[["2"]]
      )
    )
  }
)

testthat::test_that(
  "make_spatial_cross_validation_assignments() validates fold count",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::c("a", "b"),
        coord_x_km = base::c(0, 1),
        coord_y_km = base::c(0, 1),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L)
      )

    testthat::expect_error(
      make_spatial_cross_validation_assignments(
        data_locations = data_locations,
        n_folds = 3L,
        grid_cell_size_km = 5
      ),
      "number of locations"
    )
  }
)

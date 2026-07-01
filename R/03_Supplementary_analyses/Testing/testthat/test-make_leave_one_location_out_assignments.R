testthat::test_that(
  "make_leave_one_location_out_assignments() preserves locations",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::c("core_b", "core_a", "core_c"),
        coord_x_km = base::c(20, 10, 30),
        coord_y_km = base::c(50, 40, 60),
        n_samples = base::c(2L, 1L, 2L),
        row_indices = base::list(
          base::c(1L, 3L),
          2L,
          base::c(4L, 5L)
        )
      )

    data_assignments <-
      make_leave_one_location_out_assignments(
        data_locations = data_locations,
        repeat_id = 2L
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
    testthat::expect_equal(
      dplyr::pull(data_assignments, repeat_id),
      base::rep(2L, 3L)
    )
    testthat::expect_equal(
      dplyr::pull(data_assignments, fold_id),
      base::seq_len(3L)
    )
    testthat::expect_equal(
      dplyr::pull(data_assignments, location_id),
      dplyr::pull(data_locations, location_id)
    )
    testthat::expect_equal(
      dplyr::pull(data_assignments, row_indices),
      dplyr::pull(data_locations, row_indices)
    )
    testthat::expect_true(
      base::all(base::is.na(
        dplyr::pull(data_assignments, grid_cell_id)
      ))
    )
  }
)

testthat::test_that(
  "make_leave_one_location_out_assignments() validates row coverage",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::c("core_a", "core_b"),
        n_samples = base::c(2L, 1L),
        row_indices = base::list(base::c(1L, 2L), 2L)
      )

    testthat::expect_error(
      make_leave_one_location_out_assignments(data_locations),
      "exactly one location"
    )
  }
)

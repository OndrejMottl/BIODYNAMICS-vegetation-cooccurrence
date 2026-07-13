testthat::test_that(
  "make_cross_validation_branch_assignments() reuses valid assignments",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::letters[1:8],
        coord_x_km = base::c(0, 1, 2, 3, 10, 11, 12, 13),
        coord_y_km = base::c(0, 1, 2, 3, 0, 1, 2, 3),
        n_samples = base::rep(1L, 8L),
        row_indices = base::as.list(base::seq_len(8L))
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 8L,
        min_train_locations = 5L
      )
    data_shared_assignments <-
      make_spatial_cross_validation_assignments(
        data_locations = data_locations,
        n_folds = 5L,
        grid_cell_size_km = 10
      )

    data_assignments <-
      make_cross_validation_branch_assignments(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        data_shared_assignments = data_shared_assignments
      )

    testthat::expect_equal(
      base::unique(dplyr::pull(data_assignments, assignment_source)),
      "shared_pre_resolution"
    )
    testthat::expect_equal(
      base::sort(dplyr::pull(data_assignments, location_id)),
      base::letters[1:8]
    )
  }
)

testthat::test_that(
  "make_cross_validation_branch_assignments() recalibrates invalid subsets",
  {
    data_shared_locations <-
      tibble::tibble(
        location_id = base::letters[1:10],
        coord_x_km = base::c(0, 1, 2, 3, 4, 10, 11, 12, 13, 14),
        coord_y_km = base::c(0, 1, 2, 3, 4, 0, 1, 2, 3, 4),
        n_samples = base::rep(1L, 10L),
        row_indices = base::as.list(base::seq_len(10L))
      )
    data_branch_locations <-
      data_shared_locations |>
      dplyr::slice(1:8) |>
      dplyr::mutate(
        row_indices = base::as.list(base::seq_len(8L))
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 8L,
        min_train_locations = 5L
      )
    data_shared_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 10L),
        fold_id = base::c(1L, 1L, 2L, 2L, 3L, 3L, 4L, 4L, 5L, 5L),
        location_id = base::letters[1:10],
        grid_cell_id = base::rep("shared", 10L),
        n_samples = base::rep(1L, 10L),
        row_indices = base::as.list(base::seq_len(10L))
      )

    data_assignments <-
      make_cross_validation_branch_assignments(
        data_locations = data_branch_locations,
        data_fold_resolution = data_resolution,
        data_shared_assignments = data_shared_assignments,
        target_locations_per_cell = 1,
        grid_size_multipliers = base::c(1, 2, 4)
      )

    testthat::expect_equal(
      base::unique(dplyr::pull(data_assignments, assignment_source)),
      "branch_fallback"
    )
    testthat::expect_equal(
      dplyr::n_distinct(dplyr::pull(data_assignments, fold_id)),
      5L
    )
  }
)

testthat::test_that(
  "make_cross_validation_branch_assignments() supports no holdout",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::letters[1:5],
        coord_x_km = base::seq_len(5L),
        coord_y_km = base::seq_len(5L),
        n_samples = base::rep(1L, 5L),
        row_indices = base::as.list(base::seq_len(5L))
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 5L,
        min_train_locations = 5L
      )

    data_assignments <-
      make_cross_validation_branch_assignments(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        data_shared_assignments = tibble::tibble()
      )

    testthat::expect_equal(base::nrow(data_assignments), 0L)
    testthat::expect_named(
      data_assignments,
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
    )
  }
)

testthat::test_that(
  "make_cross_validation_branch_assignments() validates locations",
  {
    testthat::expect_error(
      make_cross_validation_branch_assignments(
        data_locations = tibble::tibble(location_id = "a"),
        data_fold_resolution = tibble::tibble(
          cv_strategy = "none",
          effective_folds = NA_integer_
        ),
        data_shared_assignments = tibble::tibble()
      ),
      "missing required columns"
    )
  }
)

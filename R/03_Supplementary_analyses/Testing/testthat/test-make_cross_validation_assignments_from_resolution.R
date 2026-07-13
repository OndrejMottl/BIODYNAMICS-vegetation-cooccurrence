testthat::test_that(
  "make_cross_validation_assignments_from_resolution() dispatches grouped CV",
  {
    data_locations <-
      tibble::tibble(
        location_id = letters[1:8],
        coord_x_km = base::c(0, 1, 2, 3, 10, 11, 12, 13),
        coord_y_km = base::rep(0, 8L),
        n_samples = base::rep(1L, 8L),
        row_indices = base::as.list(base::seq_len(8L))
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 8L,
        min_train_locations = 5L,
        default_folds = 3L
      )
    data_calibration <-
      tibble::tibble(
        grid_cell_size_km = 10,
        selected = TRUE
      )

    data_assignments <-
      make_cross_validation_assignments_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        data_grid_calibration = data_calibration,
        n_repeats = 2L,
        assignment_source = "shared_pre_resolution"
      )

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
    testthat::expect_equal(base::nrow(data_assignments), 16L)
    testthat::expect_equal(
      base::unique(dplyr::pull(data_assignments, assignment_source)),
      "shared_pre_resolution"
    )
  }
)

testthat::test_that(
  "make_cross_validation_assignments_from_resolution() dispatches LOO",
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

    data_assignments <-
      make_cross_validation_assignments_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        data_grid_calibration = tibble::tibble()
      )

    testthat::expect_equal(
      dplyr::pull(data_assignments, fold_id),
      base::seq_len(6L)
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(data_assignments, grid_cell_id)))
    )
  }
)

testthat::test_that(
  "make_cross_validation_assignments_from_resolution() preserves empty schema",
  {
    data_locations <-
      tibble::tibble(
        location_id = letters[1:5],
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
      make_cross_validation_assignments_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        data_grid_calibration = tibble::tibble()
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
  "make_cross_validation_assignments_from_resolution() validates provenance",
  {
    data_locations <-
      tibble::tibble(
        location_id = "a",
        coord_x_km = 1,
        coord_y_km = 1,
        n_samples = 1L,
        row_indices = base::list(1L)
      )
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 1L,
        min_train_locations = 1L
      )

    testthat::expect_error(
      make_cross_validation_assignments_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_resolution,
        data_grid_calibration = tibble::tibble(),
        assignment_source = ""
      ),
      "non-empty string"
    )
  }
)

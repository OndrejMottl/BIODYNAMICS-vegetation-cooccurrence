testthat::test_that(
  "adapt_cross_validation_assignments() falls back to LOO",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::letters[1:6],
        n_samples = base::rep(1L, 6L),
        row_indices = base::as.list(base::seq_len(6L))
      )
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 6L),
        fold_id = base::c(1L, 1L, 2L, 2L, 3L, 3L),
        location_id = base::letters[1:6],
        grid_cell_id = base::rep("cell", 6L),
        n_samples = base::rep(1L, 6L),
        row_indices = base::as.list(base::seq_len(6L)),
        cv_strategy = base::rep(
          "spatially_stratified_group_kfold",
          6L
        ),
        assignment_source = base::rep("per_id", 6L)
      )
    data_diagnostics <-
      tibble::tibble(
        cv_strategy = base::c(
          "full_model",
          base::rep("spatially_stratified_group_kfold", 3L)
        ),
        repeat_id = base::c(0L, 1L, 1L, 1L),
        effective_folds = base::c(NA_integer_, 3L, 3L, 3L),
        fold_id = base::c(0L, 1L, 2L, 3L),
        n_train_locations = base::c(6L, 4L, 4L, 4L),
        n_train_samples = base::c(6L, 4L, 4L, 4L),
        n_train_taxa = base::rep(2L, 4L),
        n_train_mem_locations = base::c(6L, 4L, 4L, 4L)
      )

    data_adapted <-
      adapt_cross_validation_assignments(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_partition_diagnostics = data_diagnostics,
        min_train_locations = 5L,
        min_train_samples = 1L,
        min_train_taxa = 1L,
        min_mem_locations = 4L
      )

    testthat::expect_equal(base::nrow(data_adapted), 6L)
    testthat::expect_equal(
      dplyr::pull(data_adapted, fold_id),
      base::seq_len(6L)
    )
    testthat::expect_equal(
      base::unique(dplyr::pull(data_adapted, cv_strategy)),
      "leave_one_location_out"
    )
    testthat::expect_equal(
      base::unique(dplyr::pull(data_adapted, assignment_source)),
      "leave_one_location_out_fallback"
    )
  }
)

testthat::test_that(
  "adapt_cross_validation_assignments() preserves feasible grouped folds",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::letters[1:8],
        n_samples = base::rep(1L, 8L),
        row_indices = base::as.list(base::seq_len(8L))
      )
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 8L),
        fold_id = base::c(1L, 1L, 2L, 2L, 3L, 3L, 4L, 5L),
        location_id = base::letters[1:8],
        grid_cell_id = base::rep("cell", 8L),
        n_samples = base::rep(1L, 8L),
        row_indices = base::as.list(base::seq_len(8L)),
        cv_strategy = base::rep(
          "spatially_stratified_group_kfold",
          8L
        ),
        assignment_source = base::rep("per_id", 8L)
      )
    data_diagnostics <-
      tibble::tibble(
        cv_strategy = base::c(
          "full_model",
          base::rep("spatially_stratified_group_kfold", 5L)
        ),
        repeat_id = base::c(0L, base::rep(1L, 5L)),
        effective_folds = base::c(NA_integer_, base::rep(5L, 5L)),
        fold_id = base::c(0L, base::seq_len(5L)),
        n_train_locations = base::c(8L, 6L, 6L, 6L, 7L, 7L),
        n_train_samples = base::c(8L, 6L, 6L, 6L, 7L, 7L),
        n_train_taxa = base::rep(2L, 6L),
        n_train_mem_locations = base::c(8L, 6L, 6L, 6L, 7L, 7L)
      )

    data_adapted <-
      adapt_cross_validation_assignments(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_partition_diagnostics = data_diagnostics,
        min_train_locations = 5L,
        min_train_samples = 1L,
        min_train_taxa = 1L,
        min_mem_locations = 4L
      )

    testthat::expect_identical(data_adapted, data_assignments)
  }
)

testthat::test_that(
  "adapt_cross_validation_assignments() validates provenance",
  {
    testthat::expect_error(
      adapt_cross_validation_assignments(
        data_locations = tibble::tibble(location_id = "a"),
        data_assignments = tibble::tibble(),
        data_partition_diagnostics = tibble::tibble(),
        min_train_locations = 1L,
        min_train_samples = 1L,
        min_train_taxa = 1L,
        min_mem_locations = 1L
      ),
      "provenance columns"
    )
  }
)

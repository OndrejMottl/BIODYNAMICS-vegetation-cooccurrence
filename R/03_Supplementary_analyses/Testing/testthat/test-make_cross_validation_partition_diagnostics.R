testthat::test_that(
  "make_cross_validation_partition_diagnostics() counts training data",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::c("a", "b", "c", "d"),
        n_samples = base::rep(2L, 4L),
        row_indices = base::list(
          base::c(1L, 2L),
          base::c(3L, 4L),
          base::c(5L, 6L),
          base::c(7L, 8L)
        )
      )

    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(base::seq_len(2L), each = 4L),
        fold_id = base::c(1L, 1L, 2L, 2L, 1L, 2L, 1L, 2L),
        location_id = base::rep(base::c("a", "b", "c", "d"), 2L),
        grid_cell_id = NA_character_,
        n_samples = base::rep(2L, 8L),
        row_indices = base::rep(
          data_locations[["row_indices"]],
          2L
        )
      )

    data_community_matrix <-
      base::matrix(
        data = base::c(
          0, 1, 0, 1, 0, 1, 0, 1,
          1, 1, 0, 0, 0, 0, 0, 0,
          1, 1, 1, 1, 1, 1, 1, 1
        ),
        nrow = 8L,
        ncol = 3L
      )
    base::colnames(data_community_matrix) <-
      base::c("variable", "rare", "constant")

    data_diagnostics <-
      make_cross_validation_partition_diagnostics(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_community_matrix = data_community_matrix,
        cv_strategy = "spatially_stratified_group_kfold",
        min_taxon_locations = 2L,
        min_taxon_samples = 2L
      )

    testthat::expect_named(
      data_diagnostics,
      base::c(
        "cv_strategy",
        "repeat_id",
        "effective_folds",
        "fold_id",
        "n_train_locations",
        "n_train_samples",
        "n_train_taxa",
        "n_train_mem_locations"
      )
    )
    testthat::expect_equal(base::nrow(data_diagnostics), 5L)

    data_full <-
      data_diagnostics |>
      dplyr::filter(cv_strategy == "full_model")

    data_folds <-
      data_diagnostics |>
      dplyr::filter(
        cv_strategy == "spatially_stratified_group_kfold"
      )

    testthat::expect_equal(dplyr::pull(data_full, n_train_locations), 4L)
    testthat::expect_equal(dplyr::pull(data_full, n_train_samples), 8L)
    testthat::expect_equal(dplyr::pull(data_full, n_train_taxa), 1L)
    testthat::expect_true(
      base::all(dplyr::pull(data_folds, n_train_locations) == 2L)
    )
    testthat::expect_true(
      base::all(dplyr::pull(data_folds, n_train_samples) == 4L)
    )
    testthat::expect_true(
      base::all(dplyr::pull(data_folds, n_train_taxa) == 1L)
    )

    data_feasibility <-
      assess_cross_validation_feasibility(
        data_partition_diagnostics = data_diagnostics,
        min_train_locations = 2L,
        min_train_samples = 4L,
        min_train_taxa = 1L,
        min_mem_locations = 2L
      )

    testthat::expect_equal(
      dplyr::pull(data_feasibility, cv_strategy),
      "spatially_stratified_group_kfold"
    )
  }
)

testthat::test_that(
  "make_cross_validation_partition_diagnostics() validates alignment",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L)
      )

    data_assignments <-
      make_leave_one_location_out_assignments(data_locations)

    data_community_invalid <-
      base::matrix(1, nrow = 3L)
    base::colnames(data_community_invalid) <- "taxon_a"

    testthat::expect_error(
      make_cross_validation_partition_diagnostics(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_community_matrix = data_community_invalid,
        cv_strategy = "leave_one_location_out"
      ),
      "row positions"
    )
  }
)

testthat::test_that(
  "make_cross_validation_partition_diagnostics() supports no holdout",
  {
    data_locations <-
      tibble::tibble(
        location_id = base::letters[1:5],
        n_samples = base::rep(1L, 5L),
        row_indices = base::as.list(base::seq_len(5L))
      )
    data_assignments <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        location_id = base::character(),
        grid_cell_id = base::character(),
        n_samples = base::integer(),
        row_indices = base::list(),
        cv_strategy = base::character(),
        assignment_source = base::character()
      )
    data_community_matrix <-
      base::matrix(
        data = base::c(0, 1, 0, 1, 0),
        ncol = 1L,
        dimnames = base::list(NULL, "taxon_a")
      )

    data_diagnostics <-
      make_cross_validation_partition_diagnostics(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_community_matrix = data_community_matrix,
        cv_strategy = "none"
      )

    testthat::expect_equal(base::nrow(data_diagnostics), 1L)
    testthat::expect_equal(
      dplyr::pull(data_diagnostics, cv_strategy),
      "full_model"
    )
    testthat::expect_equal(
      dplyr::pull(data_diagnostics, n_train_locations),
      5L
    )
  }
)

testthat::test_that(
  "assess_cross_validation_feasibility() selects strategy states",
  {
    data_full <-
      tibble::tibble(
        cv_strategy = "full_model",
        effective_folds = NA_integer_,
        fold_id = 0L,
        n_train_locations = 7L,
        n_train_samples = 70L,
        n_train_taxa = 10L,
        n_train_mem_locations = 7L
      )

    data_grouped <-
      tibble::tibble(
        cv_strategy = "spatially_stratified_group_kfold",
        effective_folds = 5L,
        fold_id = base::seq_len(5L),
        n_train_locations = base::c(5L, 5L, 6L, 6L, 6L),
        n_train_samples = base::c(50L, 52L, 55L, 56L, 57L),
        n_train_taxa = base::rep(8L, 5L),
        n_train_mem_locations = base::c(5L, 5L, 6L, 6L, 6L)
      )

    data_leave_one_out <-
      tibble::tibble(
        cv_strategy = "leave_one_location_out",
        effective_folds = 7L,
        fold_id = base::seq_len(7L),
        n_train_locations = base::rep(6L, 7L),
        n_train_samples = base::rep(60L, 7L),
        n_train_taxa = base::rep(8L, 7L),
        n_train_mem_locations = base::rep(6L, 7L)
      )

    data_partitions <-
      dplyr::bind_rows(
        data_full,
        data_grouped,
        data_leave_one_out
      )

    data_grouped_result <-
      assess_cross_validation_feasibility(
        data_partition_diagnostics = data_partitions,
        min_train_locations = 5L,
        min_train_samples = 40L,
        min_train_taxa = 5L,
        min_mem_locations = 4L
      )

    data_leave_one_out_result <-
      data_partitions |>
      dplyr::mutate(
        n_train_samples = dplyr::if_else(
          .data[["cv_strategy"]] ==
            "spatially_stratified_group_kfold" &
            .data[["fold_id"]] == 1L,
          30L,
          .data[["n_train_samples"]]
        )
      ) |>
      assess_cross_validation_feasibility(
        min_train_locations = 5L,
        min_train_samples = 40L,
        min_train_taxa = 5L,
        min_mem_locations = 4L
      )

    data_tier_pooled_result <-
      data_partitions |>
      dplyr::mutate(
        n_train_samples = dplyr::if_else(
          .data[["cv_strategy"]] ==
            "spatially_stratified_group_kfold" &
            .data[["fold_id"]] == 1L,
          30L,
          .data[["n_train_samples"]]
        ),
        n_train_taxa = dplyr::if_else(
          .data[["cv_strategy"]] == "leave_one_location_out" &
            .data[["fold_id"]] == 1L,
          4L,
          .data[["n_train_taxa"]]
        )
      ) |>
      assess_cross_validation_feasibility(
        min_train_locations = 5L,
        min_train_samples = 40L,
        min_train_taxa = 5L,
        min_mem_locations = 4L
      )

    data_no_model_result <-
      data_partitions |>
      dplyr::mutate(
        n_train_taxa = dplyr::if_else(
          .data[["cv_strategy"]] == "full_model",
          4L,
          .data[["n_train_taxa"]]
        )
      ) |>
      assess_cross_validation_feasibility(
        min_train_locations = 5L,
        min_train_samples = 40L,
        min_train_taxa = 5L,
        min_mem_locations = 4L
      )

    testthat::expect_equal(
      dplyr::pull(data_grouped_result, cv_strategy),
      "spatially_stratified_group_kfold"
    )
    testthat::expect_equal(
      dplyr::pull(data_grouped_result, effective_folds),
      5L
    )
    testthat::expect_equal(
      dplyr::pull(data_leave_one_out_result, cv_strategy),
      "leave_one_location_out"
    )
    testthat::expect_equal(
      dplyr::pull(data_tier_pooled_result, cv_feasibility_status),
      "tier_pooled_regularization_required"
    )
    testthat::expect_equal(
      dplyr::pull(data_no_model_result, cv_feasibility_status),
      "full_model_infeasible"
    )
  }
)

testthat::test_that(
  "assess_cross_validation_feasibility() validates diagnostics",
  {
    data_invalid <-
      tibble::tibble(
        cv_strategy = "full_model",
        effective_folds = NA_integer_,
        fold_id = 0L
      )

    testthat::expect_error(
      assess_cross_validation_feasibility(
        data_partition_diagnostics = data_invalid,
        min_train_locations = 5L,
        min_train_samples = 5L,
        min_train_taxa = 3L,
        min_mem_locations = 4L
      ),
      "required columns"
    )
  }
)

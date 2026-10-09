testthat::test_that("fold search selects the smallest feasible grouped count", {
  data_locations <-
    tibble::tibble(
      location_id = base::as.character(base::seq_len(60L)),
      coord_x_km = base::rep(base::seq_len(10L), 6L),
      coord_y_km = base::rep(base::seq_len(6L), each = 10L),
      n_samples = base::rep(1L, 60L),
      row_indices = base::as.list(base::seq_len(60L))
    )
  mat_community <-
    base::matrix(
      base::rep(base::c(base::rep(1, 45L), base::rep(0, 15L)), 2L),
      nrow = 60L,
      dimnames = base::list(NULL, base::c("a", "b"))
    )
  data_assignments <-
    build_spatial_cross_validation_assignments(
      data_locations = data_locations,
      n_folds = 5L,
      n_repeats = 3L,
      grid_cell_size_km = 10,
      seed = 900723L
    ) |>
    dplyr::mutate(
      cv_strategy = "spatially_stratified_group_kfold",
      assignment_source = "shared_pre_resolution"
    )
  data_diagnostics <-
    diagnose_cross_validation_partitions(
      data_locations = data_locations,
      data_assignments = data_assignments,
      data_community_matrix = mat_community,
      cv_strategy = "spatially_stratified_group_kfold"
    )
  config_cross_validation <-
    base::list(
      min_mem_locations = 4L,
      assignment_repeats = 3L,
      assignment_seed = 900723L,
      tuning_strategy = "staged",
      grid = base::list(
        target_locations_per_cell = 5,
        size_multipliers = 2 ^ base::seq(-2, 3),
        occupancy_criterion = "median",
        lower_quantile_probability = 0.25,
        max_fold_location_difference = 1L,
        max_fold_sample_difference = Inf
      )
    )
  for (
    index_case in base::seq_len(3L)
  ) {
    data_diagnostics_case <-
      diagnose_cross_validation_partitions(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_community_matrix = mat_community,
        cv_strategy = "spatially_stratified_group_kfold",
        min_taxon_locations = base::c(39L, 41L, 43L)[[index_case]]
      )
    list_search <-
      resolve_cross_validation_fold_search(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_partition_diagnostics = data_diagnostics_case,
        data_community_matrix = mat_community,
        config_data_processing = base::list(
          min_n_cores = base::c(39L, 41L, 43L)[[index_case]],
          min_n_samples = 1L,
          min_n_taxa = 2L
        ),
        config_cross_validation = config_cross_validation,
        verbose = FALSE
      )
    data_selected <-
      purrr::chuck(list_search, "data_assignments")
    testthat::expect_equal(
      dplyr::n_distinct(data_selected[["fold_id"]]),
      base::c(10L, 20L, 50L)[[index_case]]
    )
    testthat::expect_equal(base::nrow(data_selected), 180L)
    testthat::expect_equal(
      base::unique(data_selected[["assignment_source"]]),
      "grouped_fold_ladder_fallback"
    )
    testthat::expect_equal(
      base::sum(list_search[["data_fold_search"]][["selected"]]),
      1L
    )
    data_selected_checks <-
      list_search[["data_partition_diagnostics_search"]] |>
      dplyr::filter(
        .data[["attempt"]] ==
          base::max(list_search[["data_fold_search"]][["attempt"]])
      )
    testthat::expect_true(
      base::all(data_selected_checks[
        base::c("flag_locations_pass", "flag_samples_pass",
          "flag_taxa_pass", "flag_mem_pass")
      ])
    )
    testthat::expect_identical(
      resolve_cross_validation_fold_search(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_partition_diagnostics = data_diagnostics_case,
        data_community_matrix = mat_community,
        config_data_processing = base::list(
          min_n_cores = base::c(39L, 41L, 43L)[[index_case]],
          min_n_samples = 1L,
          min_n_taxa = 2L
        ),
        config_cross_validation = config_cross_validation,
        verbose = FALSE
      ),
      list_search
    )
  }
  list_preserved <-
    resolve_cross_validation_fold_search(
      data_locations = data_locations,
      data_assignments = data_assignments,
      data_partition_diagnostics = data_diagnostics,
      data_community_matrix = mat_community,
      config_data_processing = base::list(
        min_n_cores = 1L, min_n_samples = 1L, min_n_taxa = 2L
      ),
      config_cross_validation = config_cross_validation,
      verbose = FALSE
    )
  testthat::expect_identical(
    list_preserved[["data_assignments"]], data_assignments
  )
  testthat::expect_identical(
    digest::digest(list_preserved[["data_assignments"]]),
    digest::digest(data_assignments)
  )
  testthat::expect_error(
    resolve_cross_validation_fold_search(
      data_locations = data_locations,
      data_assignments = dplyr::filter(
        data_assignments, .data[["repeat_id"]] != 3L
      ),
      data_partition_diagnostics = data_diagnostics,
      data_community_matrix = mat_community,
      config_data_processing = base::list(
        min_n_cores = 1L, min_n_samples = 1L, min_n_taxa = 2L
      ),
      config_cross_validation = config_cross_validation,
      verbose = FALSE
    ),
    "every configured repeat"
  )
  for (
    min_occurrence in base::c(44L, 45L, 46L)
  ) {
    data_diagnostics_infeasible <-
      diagnose_cross_validation_partitions(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_community_matrix = mat_community,
        cv_strategy = "spatially_stratified_group_kfold",
        min_taxon_locations = min_occurrence
      )
    list_fallback <-
      resolve_cross_validation_fold_search(
        data_locations = data_locations,
        data_assignments = data_assignments,
        data_partition_diagnostics = data_diagnostics_infeasible,
        data_community_matrix = mat_community,
        config_data_processing = base::list(
          min_n_cores = min_occurrence,
          min_n_samples = 1L, min_n_taxa = 2L
        ),
        config_cross_validation = config_cross_validation,
        verbose = FALSE
      )
    if (
      min_occurrence < 46L
    ) {
      testthat::expect_equal(
        base::unique(list_fallback[["data_assignments"]][["cv_strategy"]]),
        "leave_one_location_out"
      )
      testthat::expect_equal(
        base::nrow(list_fallback[["data_assignments"]]), 60L
      )
      testthat::expect_equal(
        utils::tail(
          list_fallback[["data_fold_search"]][["cv_feasibility_status"]],
          1L
        ),
        if (
          min_occurrence == 44L
        ) "leave_one_location_out_required" else
          "tier_pooled_regularization_required"
      )
    } else {
      testthat::expect_identical(
        list_fallback[["data_assignments"]], data_assignments
      )
      testthat::expect_equal(
        list_fallback[["data_fold_search"]][["cv_feasibility_status"]],
        "full_model_infeasible"
      )
    }
  }
  testthat::expect_error(
    resolve_cross_validation_fold_search(
      data_locations = data_locations,
      data_assignments = data_assignments,
      data_partition_diagnostics = data_diagnostics_case,
      data_community_matrix = mat_community[-1L, , drop = FALSE],
      config_data_processing = base::list(
        min_n_cores = 43L, min_n_samples = 1L, min_n_taxa = 2L
      ),
      config_cross_validation = config_cross_validation,
      verbose = FALSE
    ),
    "row positions"
  )
})

testthat::test_that("fold search validates the ladder before inspecting data", {
  for (
    vec_invalid in base::list(
      NULL, base::integer(), base::c(5L, 5L), base::c(10L, 5L),
      base::c(5, 10.5), base::c(5, Inf), base::c(5, NA), "five", 1L
    )
  ) {
    testthat::expect_error(
      resolve_cross_validation_fold_search(
        grouped_fold_ladder = vec_invalid,
        verbose = FALSE
      ),
      "grouped_fold_ladder"
    )
  }
})

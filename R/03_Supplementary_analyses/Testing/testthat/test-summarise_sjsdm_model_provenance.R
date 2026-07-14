testthat::test_that(
  "summarise_sjsdm_model_provenance() records model provenance",
  {
    data_feasibility <-
      tibble::tibble(
        n_locations = 12L,
        n_samples = 40L,
        n_taxa = 8L,
        n_mem_locations = 12L,
        cv_strategy = "spatially_stratified_group_kfold",
        effective_folds = 5L,
        cv_feasibility_status = "grouped_kfold_feasible"
      )

    data_regularization <-
      tibble::tibble(
        tier_id = "paleo_spatial_regional",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "spatial=TRUE;mode=spatial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_002",
        regularization_source = "unit_cv",
        source_tier = NA_character_,
        selection_status = "selected"
      )

    data_fold_diagnostics <-
      tidyr::crossing(
        repeat_id = 1:2,
        fold_id = 1:5
      ) |>
      dplyr::mutate(
        n_taxa_retained = 7L,
        n_effective_mev = 3L,
        fit_status = "ok"
      )

    res <-
      summarise_sjsdm_model_provenance(
        data_feasibility = data_feasibility,
        data_regularization = data_regularization,
        data_fold_diagnostics = data_fold_diagnostics
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(res[["n_repeats"]], 2L)
    testthat::expect_equal(res[["n_fold_fits"]], 10L)
    testthat::expect_equal(res[["n_successful_fold_fits"]], 10L)
    testthat::expect_equal(res[["n_taxa_retained_min"]], 7L)
    testthat::expect_equal(res[["n_effective_mev"]], 3L)
    testthat::expect_equal(res[["n_effective_mev_min"]], 3L)
    testthat::expect_equal(res[["n_effective_mev_max"]], 3L)
    testthat::expect_equal(
      res[["effective_mev_status"]],
      "constant_across_folds"
    )
    testthat::expect_equal(res[["regularization_source"]], "unit_cv")
    testthat::expect_equal(
      res[["cv_strategy"]],
      "spatially_stratified_group_kfold"
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_model_provenance() records absent fold evaluation",
  {
    data_feasibility <-
      tibble::tibble(
        n_locations = 5L,
        n_samples = 20L,
        n_taxa = 4L,
        n_mem_locations = 5L,
        cv_strategy = "none",
        effective_folds = NA_integer_,
        cv_feasibility_status =
          "tier_pooled_regularization_required"
      )

    data_regularization <-
      tibble::tibble(
        tier_id = "paleo_spatial_local",
        taxonomic_resolution = "family",
        response_family = "binomial",
        predictor_structure = "spatial=TRUE;mode=spatial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_001",
        regularization_source = "tier_pooled",
        source_tier = "paleo_spatial_local",
        selection_status = "selected"
      )

    res <-
      summarise_sjsdm_model_provenance(
        data_feasibility = data_feasibility,
        data_regularization = data_regularization,
        data_fold_diagnostics = tibble::tibble()
      )

    testthat::expect_equal(res[["n_repeats"]], 0L)
    testthat::expect_equal(res[["n_fold_fits"]], 0L)
    testthat::expect_equal(res[["n_successful_fold_fits"]], 0L)
    testthat::expect_true(base::is.na(res[["n_effective_mev"]]))
    testthat::expect_true(base::is.na(res[["n_effective_mev_min"]]))
    testthat::expect_true(base::is.na(res[["n_effective_mev_max"]]))
    testthat::expect_equal(
      res[["effective_mev_status"]],
      "unavailable"
    )
    testthat::expect_equal(
      res[["regularization_source"]],
      "tier_pooled"
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_model_provenance() records varying MEV ranks",
  {
    data_feasibility <-
      tibble::tibble(
        n_locations = 9L,
        n_samples = 30L,
        n_taxa = 6L,
        n_mem_locations = 9L,
        cv_strategy = "spatially_stratified_group_kfold",
        effective_folds = 3L,
        cv_feasibility_status = "grouped_kfold_feasible"
      )

    data_regularization <-
      tibble::tibble(
        tier_id = "paleo_spatial_regional",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "spatial=TRUE;mode=spatial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_003",
        regularization_source = "unit_cv",
        source_tier = NA_character_,
        selection_status = "selected"
      )

    data_fold_diagnostics <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 1:3,
        n_taxa_retained = base::c(5L, 4L, 5L),
        n_effective_mev = base::c(2L, 3L, 4L),
        fit_status = "ok"
      )

    res <-
      summarise_sjsdm_model_provenance(
        data_feasibility = data_feasibility,
        data_regularization = data_regularization,
        data_fold_diagnostics = data_fold_diagnostics
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(res[["n_successful_fold_fits"]], 3L)
    testthat::expect_equal(res[["n_taxa_retained_min"]], 4L)
    testthat::expect_true(base::is.na(res[["n_effective_mev"]]))
    testthat::expect_equal(res[["n_effective_mev_min"]], 2L)
    testthat::expect_equal(res[["n_effective_mev_max"]], 4L)
    testthat::expect_equal(
      res[["effective_mev_status"]],
      "varies_by_fold"
    )

    invalid_effective_mev_values <-
      base::list(
        -1L,
        1.5,
        Inf,
        base::as.double(.Machine[["integer.max"]]) + 1,
        "three"
      )

    invalid_effective_mev_values |>
      purrr::walk(
        .f = ~ {
          data_invalid_diagnostics <-
            data_fold_diagnostics

          data_invalid_diagnostics[["n_effective_mev"]] <-
            base::rep(.x, base::nrow(data_invalid_diagnostics))

          testthat::expect_error(
            summarise_sjsdm_model_provenance(
              data_feasibility = data_feasibility,
              data_regularization = data_regularization,
              data_fold_diagnostics = data_invalid_diagnostics
            ),
            "Effective MEV counts must be non-negative integers"
          )
        }
      )
  }
)

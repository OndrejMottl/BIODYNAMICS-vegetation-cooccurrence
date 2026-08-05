testthat::test_that(
  ".fit_decomposition_variant() returns an empty row after fit errors",
  {
    data_fold_input <-
      base::list(
        data_train_input = base::list(
          data_abiotic_to_fit = base::data.frame(x = base::c(1, 2))
        ),
        data_test_input = base::list(
          data_abiotic_to_fit = base::data.frame(x = 3),
          data_spatial_to_fit = base::data.frame(spatial = 1)
        ),
        data_diagnostics = tibble::tibble(
          n_train_samples = 2L,
          n_test_samples = 1L,
          n_taxa_raw = 2L,
          n_taxa_retained = 2L,
          n_taxa_dropped = 0L
        ),
        data_test_observed = base::matrix(
          base::c(1, 0),
          nrow = 1L
        )
      )

    res <-
      .fit_decomposition_variant(
        data_fold_input = data_fold_input,
        route_id = "route_a",
        repeat_id = 1L,
        fold_id = "fold_001",
        variant_name = "no_abiotic",
        list_variant = base::list(
          spatial_method = "linear",
          biotic = NULL
        ),
        age_formula_mode = "none",
        config_model_fitting = base::list(error_family = "binomial"),
        fit_config = base::list(),
        fit_fn = function(...) {
          base::stop("fit failed")
        },
        predict_fn = stats::predict,
        convergence_fn = diagnose_jsdm_convergence
      )

    testthat::expect_identical(res[["status"]], "error")
    testthat::expect_identical(res[["error_message"]], "fit failed")
    testthat::expect_equal(res[["n_train_samples"]], 2L)
  }
)

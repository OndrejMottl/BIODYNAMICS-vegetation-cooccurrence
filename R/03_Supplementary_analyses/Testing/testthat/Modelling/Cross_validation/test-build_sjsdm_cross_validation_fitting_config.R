testthat::test_that(
  "build_sjsdm_cross_validation_fitting_config isolates CV budgets",
  {
    config_final <-
      base::list(
        n_cores = 5L,
        n_iter = 12000L,
        n_sampling = 2000L,
        n_step_size = 32L,
        n_early_stopping = 0L,
        n_samples_anova = 1000L,
        error_family = "binomial",
        use_spatial = TRUE
      )
    config_budget <-
      base::list(
        n_iter_initial = 1000L,
        n_iter_max = 4000L,
        n_sampling = 200L,
        n_step_size = NULL,
        n_early_stopping = NULL
      )

    res <-
      build_sjsdm_cross_validation_fitting_config(
        config_model_fitting = config_final,
        config_fit_budget = config_budget
      )

    testthat::expect_equal(res[["n_iter"]], 1000L)
    testthat::expect_equal(res[["n_iter_initial"]], 1000L)
    testthat::expect_equal(res[["n_iter_max"]], 4000L)
    testthat::expect_equal(res[["n_sampling"]], 200L)
    testthat::expect_null(res[["n_step_size"]])
    testthat::expect_null(res[["n_early_stopping"]])
    testthat::expect_true("n_step_size" %in% base::names(res))
    testthat::expect_true("n_early_stopping" %in% base::names(res))
    testthat::expect_false("n_samples_anova" %in% base::names(res))
    testthat::expect_equal(config_final[["n_iter"]], 12000L)
    testthat::expect_equal(config_final[["n_sampling"]], 2000L)
  }
)

testthat::test_that(
  "build_sjsdm_cross_validation_fitting_config validates budgets",
  {
    config_final <-
      base::list(
        n_cores = 5L,
        n_iter = 500L,
        n_sampling = 200L,
        n_step_size = NULL,
        n_early_stopping = NULL,
        n_samples_anova = 1000L,
        error_family = "binomial",
        use_spatial = TRUE
      )

    testthat::expect_error(
      build_sjsdm_cross_validation_fitting_config(
        config_model_fitting = config_final,
        config_fit_budget = base::list(
          n_iter_initial = 2000L,
          n_iter_max = 1000L,
          n_sampling = 200L,
          n_step_size = NULL,
          n_early_stopping = NULL
        )
      ),
      regexp = "n_iter_max"
    )

    testthat::expect_error(
      build_sjsdm_cross_validation_fitting_config(
        config_model_fitting = config_final,
        config_fit_budget = base::list(
          n_iter_initial = 500L,
          n_iter_max = 2000L,
          n_sampling = NA_integer_,
          n_step_size = NULL,
          n_early_stopping = NULL
        )
      ),
      regexp = "n_sampling"
    )
  }
)

testthat::test_that(
  "build_sjsdm_cross_validation_fitting_config blocks pending production",
  {
    config_final <-
      base::list(
        n_cores = 5L,
        n_iter = 500L,
        n_sampling = 200L,
        n_step_size = NULL,
        n_early_stopping = NULL,
        n_samples_anova = 1000L,
        error_family = "binomial",
        use_spatial = TRUE
      )
    config_budget <-
      base::list(
        calibration_status = "pending_calibration",
        n_iter_initial = 500L,
        n_iter_max = 2000L,
        n_sampling = 200L,
        n_step_size = NULL,
        n_early_stopping = NULL
      )

    error_condition <-
      testthat::expect_error(
        build_sjsdm_cross_validation_fitting_config(
          config_model_fitting = config_final,
          config_fit_budget = config_budget
        )
      )
    error_message <-
      base::conditionMessage(error_condition)

    testthat::expect_match(
      error_message,
      "01_run_preparation.R",
      fixed = TRUE
    )
    testthat::expect_match(
      error_message,
      "01_run_model_calibration.R",
      fixed = TRUE
    )
    testthat::expect_match(error_message, "config.yml", fixed = TRUE)
    testthat::expect_match(error_message, "will be reused", fixed = TRUE)
    testthat::expect_match(error_message, "not used as CV fallbacks")

    config_budget_calibrated <-
      purrr::list_modify(
        config_budget,
        calibration_status = "calibrated"
      )
    testthat::expect_silent(
      build_sjsdm_cross_validation_fitting_config(
        config_model_fitting = config_final,
        config_fit_budget = config_budget_calibrated
      )
    )
  }
)

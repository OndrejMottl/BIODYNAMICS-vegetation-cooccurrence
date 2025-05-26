testthat::test_that(
  desc = "return correct class",
  code = {
    invisible(
      capture.output({
        mod_example_full <-
          Hmsc::Hmsc(
            Y = Hmsc::TD$Y,
            XData = Hmsc::TD$X,
            XFormula = ~ x1 + x2,
            distr = "probit"
          ) %>%
          fit_hmsc_model(
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    invisible(
      capture.output({
        mod_example_null <-
          Hmsc::Hmsc(
            Y = Hmsc::TD$Y,
            XData = Hmsc::TD$X,
            XFormula = ~1,
            distr = "probit"
          ) %>%
          fit_hmsc_model(
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    example_pred_full <-
      Hmsc::computePredictedValues(
        mod_example_full,
        nChains = 1,
        nParallel = 1
      )

    example_pred_null <-
      Hmsc::computePredictedValues(
        mod_example_null,
        nChains = 1,
        nParallel = 1
      )

    example_eval_full <-
      add_model_evaluation(
        mod_fitted = mod_example_full,
        data_pred = example_pred_full
      )


    suppressWarnings(
      example_eval_null <-
        add_model_evaluation(
          mod_fitted = mod_example_null,
          data_pred = example_pred_null
        )
    )

    result <-
      get_better_model_based_on_fit(
        list_models = list(
          mod_null = example_eval_null,
          mod_full = example_eval_full
        )
      )

    testthat::expect_type(
      result,
      "list"
    )
  }
)

testthat::test_that(
  desc = "return correct data",
  code = {
    invisible(
      capture.output({
        mod_example_full <-
          Hmsc::Hmsc(
            Y = Hmsc::TD$Y,
            XData = Hmsc::TD$X,
            XFormula = ~ x1 + x2,
            distr = "probit"
          ) %>%
          fit_hmsc_model(
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    invisible(
      capture.output({
        mod_example_null <-
          Hmsc::Hmsc(
            Y = Hmsc::TD$Y,
            XData = Hmsc::TD$X,
            XFormula = ~1,
            distr = "probit"
          ) %>%
          fit_hmsc_model(
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    example_pred_full <-
      Hmsc::computePredictedValues(
        mod_example_full,
        nChains = 1,
        nParallel = 1
      )

    example_pred_null <-
      Hmsc::computePredictedValues(
        mod_example_null,
        nChains = 1,
        nParallel = 1
      )

    example_eval_full <-
      add_model_evaluation(
        mod_fitted = mod_example_full,
        data_pred = example_pred_full
      )


    suppressWarnings(
      example_eval_null <-
        add_model_evaluation(
          mod_fitted = mod_example_null,
          data_pred = example_pred_null
        )
    )

    result <-
      get_better_model_based_on_fit(
        list_models = list(
          mod_null = example_eval_null,
          mod_full = example_eval_full
        )
      )

    testthat::expect_identical(
      result,
      example_eval_full
    )
  }
)

testthat::test_that(
  desc = "handle invalid input",
  code = {
    invisible(
      capture.output({
        mod_example_full <-
          Hmsc::Hmsc(
            Y = Hmsc::TD$Y,
            XData = Hmsc::TD$X,
            XFormula = ~ x1 + x2,
            distr = "probit"
          ) %>%
          fit_hmsc_model(
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    invisible(
      capture.output({
        mod_example_null <-
          Hmsc::Hmsc(
            Y = Hmsc::TD$Y,
            XData = Hmsc::TD$X,
            XFormula = ~1,
            distr = "probit"
          ) %>%
          fit_hmsc_model(
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    example_pred_full <-
      Hmsc::computePredictedValues(
        mod_example_full,
        nChains = 1,
        nParallel = 1
      )

    example_pred_null <-
      Hmsc::computePredictedValues(
        mod_example_null,
        nChains = 1,
        nParallel = 1
      )

    example_eval_full <-
      add_model_evaluation(
        mod_fitted = mod_example_full,
        data_pred = example_pred_full
      )


    suppressWarnings(
      example_eval_null <-
        add_model_evaluation(
          mod_fitted = mod_example_null,
          data_pred = example_pred_null
        )
    )

    testthat::expect_error(
      get_better_model_based_on_fit(
        list_models = NULL
      )
    )

    testthat::expect_error(
      get_better_model_based_on_fit(
        list_models = "invalid_list"
      )
    )

    testthat::expect_error(
      get_better_model_based_on_fit(
        list_models = list()
      )
    )

    testthat::expect_error(
      get_better_model_based_on_fit(
        list_models = list(
          mod_null = NULL,
          mod_full = example_eval_full
        )
      )
    )

    testthat::expect_error(
      get_better_model_based_on_fit(
        list_models = list(
          mod_null = example_eval_null,
          mod_full = NULL
        )
      )
    )
  }
)

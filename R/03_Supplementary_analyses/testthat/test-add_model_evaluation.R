testthat::test_that(
  desc = "return correct class",
  code = {
    mod_example <-
      Hmsc::TD$m

    example_pred <-
      Hmsc::computePredictedValues(
        mod_example,
        nChains = 1,
        nParallel = 1
      )

    result <-
      add_model_evaluation(
        mod_fitted = mod_example,
        data_pred = example_pred
      )

    testthat::expect_type(
      result,
      "list"
    )
  }
)

testthat::test_that(
  desc = "return correct data structure",
  code = {
    mod_example <-
      Hmsc::TD$m

    example_pred <-
      Hmsc::computePredictedValues(
        mod_example,
        nChains = 1,
        nParallel = 1
      )

    result <-
      add_model_evaluation(
        mod_fitted = mod_example,
        data_pred = example_pred
      )

    testthat::expect_length(
      result,
      2
    )

    testthat::expect_true(
      all(c("mod", "eval") %in% names(result))
    )

    testthat::expect_true(
      !is.null(result$mod) &&
        !is.null(result$eval)
    )

    testthat::expect_length(
      result$eval,
      3
    )

    testthat::expect_true(
      all(c("RMSE", "AUC", "TjurR2") %in% names(result$eval))
    )

    testthat::expect_true(
      !is.null(result$eval$AUC) &&
        !is.null(result$eval$RMSE) &&
        !is.null(result$eval$TjurR2)
    )
  }
)

testthat::test_that(
  desc = "handle invalid input",
  code = {
    mod_example <-
      Hmsc::TD$m

    example_pred <-
      Hmsc::computePredictedValues(
        mod_example,
        nChains = 1,
        nParallel = 1
      )

    testthat::expect_error(
      add_model_evaluation(
        mod_fitted = NULL,
        data_pred = example_pred
      )
    )

    testthat::expect_error(
      add_model_evaluation(
        mod_fitted = "invalid_model",
        data_pred = example_pred
      )
    )

    testthat::expect_error(
      add_model_evaluation(
        mod_fitted = mod_example,
        data_pred = NULL,
      )
    )

    testthat::expect_error(
      add_model_evaluation(
        mod_fitted = mod_example,
        data_pred = "invalid_data_pred",
      )
    )
  }
)

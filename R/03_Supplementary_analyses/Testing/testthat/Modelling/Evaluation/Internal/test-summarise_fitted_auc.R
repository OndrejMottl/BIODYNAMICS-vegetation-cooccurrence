testthat::test_that(
  ".summarise_fitted_auc() preserves finite fitted AUC summaries",
  {
    data_result <-
      .summarise_fitted_auc(
        model_evaluation_fitted = base::list(
          species = tibble::tibble(AUC = base::c(0.7, NA_real_, 0.9))
        )
      )

    testthat::expect_equal(dplyr::pull(data_result, fitted_auc_mean), 0.8)
    testthat::expect_equal(dplyr::pull(data_result, fitted_auc_median), 0.8)
    testthat::expect_equal(dplyr::pull(data_result, fitted_auc_n), 2L)
  }
)

testthat::test_that(
  ".summarise_fitted_auc() returns typed defaults for missing results",
  {
    data_result <-
      .summarise_fitted_auc(model_evaluation_fitted = NULL)

    testthat::expect_true(
      base::is.na(dplyr::pull(data_result, fitted_auc_mean))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(data_result, fitted_auc_median))
    )
    testthat::expect_identical(dplyr::pull(data_result, fitted_auc_n), 0L)
  }
)

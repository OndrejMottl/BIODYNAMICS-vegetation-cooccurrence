testthat::test_that(
  "evaluate_binary_auc() calculates known values and ties",
  {
    data_perfect <-
      evaluate_binary_auc(
        observed = base::c(0, 0, 1, 1),
        predicted_probability = base::c(0.1, 0.2, 0.8, 0.9)
      )

    data_tied <-
      evaluate_binary_auc(
        observed = base::c(0, 1, 0, 1),
        predicted_probability = base::rep(0.5, 4L)
      )

    testthat::expect_equal(dplyr::pull(data_perfect, auc), 1)
    testthat::expect_equal(dplyr::pull(data_tied, auc), 0.5)
  }
)

testthat::test_that(
  "evaluate_binary_auc() reports undefined one-class taxa",
  {
    data_result <-
      evaluate_binary_auc(
        observed = base::c(0, 0),
        predicted_probability = base::c(0.1, 0.2)
      )

    testthat::expect_true(base::is.na(dplyr::pull(data_result, auc)))
    testthat::expect_equal(
      dplyr::pull(data_result, metric_status),
      "undefined_no_presences"
    )
  }
)

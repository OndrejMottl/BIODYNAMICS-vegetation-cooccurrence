testthat::test_that(
  "evaluate_binary_brier_score() calculates a known value",
  {
    data_result <-
      evaluate_binary_brier_score(
        observed = base::c(0, 1),
        predicted_probability = base::c(0.25, 0.75)
      )

    testthat::expect_equal(
      dplyr::pull(data_result, brier_score),
      0.0625
    )
    testthat::expect_equal(
      dplyr::pull(data_result, metric_status),
      "ok"
    )
  }
)

testthat::test_that(
  "evaluate_binary_brier_score() remains defined for one class",
  {
    data_result <-
      evaluate_binary_brier_score(
        observed = base::c(1, 1),
        predicted_probability = base::c(0.8, 0.6)
      )

    testthat::expect_equal(
      dplyr::pull(data_result, brier_score),
      0.1
    )
    testthat::expect_equal(
      dplyr::pull(data_result, metric_status),
      "ok"
    )
  }
)

testthat::test_that(
  "evaluate_binary_brier_score() validates probabilities",
  {
    testthat::expect_error(
      evaluate_binary_brier_score(
        observed = base::c(0, 1),
        predicted_probability = base::c(0.2, 1.2)
      ),
      "closed interval"
    )
  }
)

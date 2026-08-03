testthat::test_that(
  "evaluate_binary_log_loss() calculates a known value",
  {
    data_result <-
      evaluate_binary_log_loss(
        observed = base::c(0, 1),
        predicted_probability = base::c(0.25, 0.75)
      )

    testthat::expect_equal(
      dplyr::pull(data_result, log_loss),
      -base::log(0.75)
    )
    testthat::expect_equal(
      dplyr::pull(data_result, metric_status),
      "ok"
    )
  }
)

testthat::test_that(
  "evaluate_binary_log_loss() clips boundary probabilities",
  {
    data_result <-
      evaluate_binary_log_loss(
        observed = base::c(1, 0),
        predicted_probability = base::c(0, 1),
        epsilon = 1e-6
      )

    testthat::expect_true(
      base::is.finite(dplyr::pull(data_result, log_loss))
    )
    testthat::expect_equal(
      dplyr::pull(data_result, log_loss),
      -base::log(1e-6)
    )
  }
)

testthat::test_that(
  "evaluate_binary_log_loss() validates epsilon",
  {
    testthat::expect_error(
      evaluate_binary_log_loss(
        observed = base::c(0, 1),
        predicted_probability = base::c(0.2, 0.8),
        epsilon = 0.5
      ),
      "epsilon"
    )
  }
)

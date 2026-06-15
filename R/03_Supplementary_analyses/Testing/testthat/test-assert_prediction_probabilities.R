testthat::test_that(
  "assert_prediction_probabilities() accepts bounded predictions",
  {
    mat_predictions <-
      base::matrix(
        data = c(0, 0.25, 0.75, 1),
        nrow = 2
      )

    res <-
      assert_prediction_probabilities(
        data_predictions = mat_predictions
      )

    testthat::expect_equal(res, mat_predictions)
  }
)

testthat::test_that(
  "assert_prediction_probabilities() rejects invalid values",
  {
    mat_predictions <-
      base::matrix(
        data = c(0.1, 1.2),
        nrow = 1
      )

    testthat::expect_error(
      assert_prediction_probabilities(
        data_predictions = mat_predictions
      ),
      regexp = "probabilities"
    )

    testthat::expect_error(
      assert_prediction_probabilities(
        data_predictions = base::matrix(NA_real_, nrow = 1)
      ),
      regexp = "finite"
    )
  }
)

testthat::test_that(
  "evaluate_tjur_r2() calculates known and negative values",
  {
    data_positive <-
      evaluate_tjur_r2(
        observed = base::c(0, 0, 1, 1),
        predicted_probability = base::c(0.1, 0.3, 0.6, 0.8)
      )

    data_negative <-
      evaluate_tjur_r2(
        observed = base::c(0, 0, 1, 1),
        predicted_probability = base::c(0.8, 0.6, 0.3, 0.1)
      )

    testthat::expect_equal(dplyr::pull(data_positive, tjur_r2), 0.5)
    testthat::expect_equal(dplyr::pull(data_negative, tjur_r2), -0.5)
    testthat::expect_equal(
      dplyr::pull(data_positive, metric_status),
      "ok"
    )
  }
)

testthat::test_that(
  "evaluate_tjur_r2() reports undefined one-class taxa",
  {
    data_result <-
      evaluate_tjur_r2(
        observed = base::c(1, 1),
        predicted_probability = base::c(0.7, 0.9)
      )

    testthat::expect_true(
      base::is.na(dplyr::pull(data_result, tjur_r2))
    )
    testthat::expect_equal(
      dplyr::pull(data_result, metric_status),
      "undefined_no_absences"
    )
  }
)

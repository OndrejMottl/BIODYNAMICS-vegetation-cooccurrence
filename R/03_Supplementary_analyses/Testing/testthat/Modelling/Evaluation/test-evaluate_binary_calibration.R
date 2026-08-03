testthat::test_that(
  "evaluate_binary_calibration() estimates defined coefficients",
  {
    data_result <-
      evaluate_binary_calibration(
        observed = base::c(0, 1, 0, 1, 0, 1),
        predicted_probability = base::c(0.1, 0.3, 0.4, 0.6, 0.7, 0.9)
      )

    testthat::expect_true(
      base::is.finite(dplyr::pull(data_result, calibration_intercept))
    )
    testthat::expect_true(
      base::is.finite(dplyr::pull(data_result, calibration_slope))
    )
    testthat::expect_equal(
      dplyr::pull(data_result, intercept_status),
      "ok"
    )
    testthat::expect_equal(
      dplyr::pull(data_result, slope_status),
      "ok"
    )
  }
)
testthat::test_that(
  "evaluate_binary_calibration() identifies constant predictions",
  {
    data_result <-
      evaluate_binary_calibration(
        observed = base::c(0, 1, 0, 1),
        predicted_probability = base::rep(0.5, 4L)
      )

    testthat::expect_equal(
      dplyr::pull(data_result, calibration_intercept),
      0,
      tolerance = 1e-8
    )
    testthat::expect_equal(
      dplyr::pull(data_result, intercept_status),
      "ok"
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(data_result, calibration_slope))
    )
    testthat::expect_equal(
      dplyr::pull(data_result, slope_status),
      "undefined_constant_predictions"
    )
  }
)

testthat::test_that(
  "evaluate_binary_calibration() identifies one class and separation",
  {
    data_one_class <-
      evaluate_binary_calibration(
        observed = base::c(1, 1),
        predicted_probability = base::c(0.6, 0.8)
      )

    testthat::expect_true(
      base::all(
        base::is.na(
          base::c(
            dplyr::pull(data_one_class, calibration_intercept),
            dplyr::pull(data_one_class, calibration_slope)
          )
        )
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_one_class, intercept_status),
      "undefined_no_absences"
    )
    testthat::expect_equal(
      dplyr::pull(data_one_class, slope_status),
      "undefined_no_absences"
    )

    data_separated <-
      evaluate_binary_calibration(
        observed = base::c(0, 0, 1, 1),
        predicted_probability = base::c(0.1, 0.2, 0.8, 0.9)
      )

    testthat::expect_equal(
      dplyr::pull(data_separated, intercept_status),
      "ok"
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(data_separated, calibration_slope))
    )
    testthat::expect_equal(
      dplyr::pull(data_separated, slope_status),
      "undefined_separation"
    )
  }
)

testthat::test_that(
  "evaluate_binary_calibration() validates epsilon",
  {
    testthat::expect_error(
      evaluate_binary_calibration(
        observed = base::c(0, 1),
        predicted_probability = base::c(0.2, 0.8),
        epsilon = 0.5
      ),
      "epsilon"
    )
  }
)

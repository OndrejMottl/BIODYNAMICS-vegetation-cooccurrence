testthat::test_that(
  ".fit_binary_calibration_model() returns model and warning state",
  {
    data_calibration <-
      tibble::tibble(
        observed = base::c(0, 1, 0, 1, 0, 1),
        predicted_logit = base::c(-2, -1, -0.5, 0.5, 1, 2)
      )

    list_result <-
      .fit_binary_calibration_model(
        formula_calibration = observed ~ predicted_logit,
        data_calibration = data_calibration
      )

    testthat::expect_named(list_result, base::c("model", "flag_warning"))
    testthat::expect_s3_class(
      purrr::chuck(list_result, "model"),
      "glm"
    )
    testthat::expect_false(purrr::chuck(list_result, "flag_warning"))
  }
)

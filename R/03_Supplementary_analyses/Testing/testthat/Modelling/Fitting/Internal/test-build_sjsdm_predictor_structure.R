testthat::test_that(
  ".build_sjsdm_predictor_structure() preserves linear settings",
  {
    data_predictors <-
      base::data.frame(
        predictor_a = base::c(1, 2, 3),
        predictor_b = base::c(4, 5, 6)
      )

    result <-
      .build_sjsdm_predictor_structure(
        data_predictors = data_predictors,
        predictor_formula = ~ predictor_a + predictor_b,
        predictor_method = "linear",
        lambda = 0.2,
        alpha = 0.3
      )

    testthat::expect_s3_class(result, "linear")
    testthat::expect_identical(
      result |>
        purrr::chuck("data"),
      data_predictors
    )
    testthat::expect_equal(
      result |>
        purrr::chuck("l1_coef"),
      0.14
    )
    testthat::expect_equal(
      result |>
        purrr::chuck("l2_coef"),
      0.06
    )
  }
)

testthat::test_that(
  ".build_sjsdm_predictor_structure() supports DNN and none",
  {
    data_predictors <-
      base::data.frame(
        predictor_a = base::c(1, 2, 3)
      )

    result_dnn <-
      .build_sjsdm_predictor_structure(
        data_predictors = data_predictors,
        predictor_formula = ~ predictor_a,
        predictor_method = "DNN"
      )

    result_none <-
      .build_sjsdm_predictor_structure(
        data_predictors = NULL,
        predictor_formula = ~ predictor_a,
        predictor_method = "none"
      )

    testthat::expect_s3_class(result_dnn, "DNN")
    testthat::expect_null(result_none)
  }
)

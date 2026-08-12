testthat::test_that(
  "evaluate_sjsdm_prediction_source_metrics() returns six metrics",
  {
    res <-
      evaluate_sjsdm_prediction_source_metrics(
        vec_observed = base::c(0, 1, 0, 1),
        vec_probability = base::c(0.1, 0.8, 0.2, 0.9),
        prediction_source = "model",
        flag_complete = TRUE,
        incomplete_status = "incomplete_predictions"
      )

    testthat::expect_equal(base::nrow(res), 6L)
    testthat::expect_identical(
      res[["prediction_source"]],
      base::rep("model", 6L)
    )
  }
)

testthat::test_that(
  "build_sjsdm_empty_unit_regularization_selection() preserves schema",
  {
    res <-
      build_sjsdm_empty_unit_regularization_selection()

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_identical(
      base::vapply(res, base::typeof, base::character(1L)),
      base::c(
        candidate_id = "character",
        alpha_cov = "double",
        alpha_coef = "double",
        alpha_spatial = "double",
        lambda_cov = "double",
        lambda_coef = "double",
        lambda_spatial = "double",
        selection_metric = "character",
        selection_metric_value = "double",
        n_repeats = "integer",
        candidate_rank = "integer",
        cv_strategy = "character",
        regularization_source = "character"
      )
    )
  }
)

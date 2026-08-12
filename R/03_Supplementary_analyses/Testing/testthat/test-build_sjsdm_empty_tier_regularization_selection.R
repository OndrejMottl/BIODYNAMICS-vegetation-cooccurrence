testthat::test_that(
  "build_sjsdm_empty_tier_regularization_selection() preserves schema",
  {
    res <-
      build_sjsdm_empty_tier_regularization_selection()

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_s3_class(res[["created_at"]], "POSIXct")
    testthat::expect_type(res[["source_ids"]], "list")
  }
)

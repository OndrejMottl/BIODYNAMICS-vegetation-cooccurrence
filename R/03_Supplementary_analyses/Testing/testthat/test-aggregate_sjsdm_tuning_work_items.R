testthat::test_that(
  "aggregate_sjsdm_tuning_work_items() returns typed empty results",
  {
    res <-
      aggregate_sjsdm_tuning_work_items(base::list())

    testthat::expect_named(
      res,
      base::c("data_tuning", "list_prediction_cache")
    )
    testthat::expect_equal(base::nrow(res[["data_tuning"]]), 0L)
    testthat::expect_length(res[["list_prediction_cache"]], 0L)
  }
)

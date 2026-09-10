testthat::test_that(
  "build_sjsdm_cv_calibration_ladder follows iteration and sampling policy",
  {
    res <-
      build_sjsdm_cv_calibration_ladder()

    testthat::expect_equal(
      res[["n_iter"]][1:8],
      c(500L, 1000L, 2000L, 4000L, 8000L, 16000L, 32000L, 64000L)
    )
    testthat::expect_equal(res[["n_sampling"]][1:8], rep(200L, 8L))
    testthat::expect_equal(
      res[["n_sampling"]][9:14],
      c(400L, 800L, 1600L, 3200L, 6400L, 8000L)
    )
    testthat::expect_equal(res[["n_iter"]][9:14], rep(64000L, 6L))
    testthat::expect_equal(res[["budget_order"]], 1:14)
  }
)

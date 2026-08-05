testthat::test_that(
  ".load_decomposition_target() forwards the target and store",
  {
    tar_read_fn <- function(name, store) {
      base::list(name = name, store = store)
    }

    res <-
      .load_decomposition_target(
        target_name = "target_a",
        store_path = "store_a",
        tar_read_fn = tar_read_fn
      )

    testthat::expect_identical(
      res,
      base::list(name = "target_a", store = "store_a")
    )
  }
)

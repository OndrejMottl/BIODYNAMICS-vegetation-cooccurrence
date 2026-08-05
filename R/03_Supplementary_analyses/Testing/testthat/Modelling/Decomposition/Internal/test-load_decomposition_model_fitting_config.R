testthat::test_that(
  ".load_decomposition_model_fitting_config() uses resolution fallback",
  {
    tar_read_fn <- function(name, store) {
      if (
        name == "config_model_fitting"
      ) {
        base::stop("missing")
      }

      return(base::list(name = name, store = store))
    }

    res <-
      .load_decomposition_model_fitting_config(
        store_path = "store_a",
        resolution_id = "genus",
        tar_read_fn = tar_read_fn
      )

    testthat::expect_identical(
      base::as.character(res[["name"]]),
      "config_model_fitting_genus"
    )
    testthat::expect_identical(res[["store"]], "store_a")
  }
)

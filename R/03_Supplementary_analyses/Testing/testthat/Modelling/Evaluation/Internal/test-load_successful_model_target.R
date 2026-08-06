testthat::test_that(
  ".load_successful_model_target() loads only successful targets",
  {
    data_meta <-
      tibble::tibble(
        name = base::c("target_ok", "target_failed"),
        error = base::c(NA_character_, "failed")
      )

    fake_reader <- function(name, store) {
      base::list(name = name, store = store)
    }

    list_result <-
      .load_successful_model_target(
        data_meta = data_meta,
        target_name = "target_ok",
        store_path = "store",
        read_target_fn = fake_reader
      )

    testthat::expect_identical(
      list_result,
      base::list(name = "target_ok", store = "store")
    )
    testthat::expect_null(
      .load_successful_model_target(
        data_meta = data_meta,
        target_name = "target_failed",
        store_path = "store",
        read_target_fn = fake_reader
      )
    )
  }
)

testthat::test_that(
  ".load_successful_model_target() converts loading errors to NULL",
  {
    testthat::expect_null(
      .load_successful_model_target(
        data_meta = tibble::tibble(
          name = "target_ok",
          error = NA_character_
        ),
        target_name = "target_ok",
        store_path = "store",
        read_target_fn = function(name, store) {
          base::stop("cannot load")
        }
      )
    )
  }
)

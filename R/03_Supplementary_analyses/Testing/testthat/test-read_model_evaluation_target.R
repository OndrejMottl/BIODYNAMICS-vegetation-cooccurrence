testthat::test_that(
  "read_model_evaluation_target() reads expected target name",
  {
    fake_reader <- function(name, store) {
      base::list(
        name = name,
        store = store
      )
    }

    res <-
      read_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        read_target_fn = fake_reader
      )

    testthat::expect_identical(
      purrr::chuck(res, "name"),
      "model_evaluation_genus"
    )
    testthat::expect_identical(purrr::chuck(res, "store"), "store")
  }
)

testthat::test_that(
  "read_model_evaluation_target() returns NULL when read fails",
  {
    fake_reader <- function(name, store) {
      base::stop("cannot read")
    }

    res <-
      read_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        read_target_fn = fake_reader
      )

    testthat::expect_null(res)
  }
)

testthat::test_that(
  "read_model_evaluation_target() validates arguments",
  {
    fake_reader <- function(name, store) {
      base::list()
    }

    testthat::expect_error(
      read_model_evaluation_target(
        store_path = character(),
        resolution_id = "genus",
        read_target_fn = fake_reader
      ),
      regexp = "store_path"
    )
  }
)

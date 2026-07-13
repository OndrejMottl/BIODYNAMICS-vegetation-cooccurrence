testthat::test_that(
  "read_model_evaluation_target() reads explicit evaluation targets",
  {
    fake_reader <- function(name, store) {
      base::list(
        name = name,
        store = store
      )
    }

    res_fitted <-
      read_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "fitted",
        read_target_fn = fake_reader
      )

    testthat::expect_identical(
      purrr::chuck(res_fitted, "name"),
      "model_evaluation_fitted_genus"
    )

    res_cross_validated <-
      read_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "cross_validated",
        read_target_fn = fake_reader
      )

    testthat::expect_identical(
      purrr::chuck(res_cross_validated, "name"),
      "model_evaluation_cross_validated_genus"
    )
    testthat::expect_identical(
      purrr::chuck(res_cross_validated, "store"),
      "store"
    )
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
        evaluation_type = "fitted",
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
        evaluation_type = "fitted",
        read_target_fn = fake_reader
      ),
      regexp = "store_path"
    )

    testthat::expect_error(
      read_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "combined",
        read_target_fn = fake_reader
      ),
      regexp = "evaluation_type"
    )
  }
)

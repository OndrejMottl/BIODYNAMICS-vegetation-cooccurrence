testthat::test_that(
  "read_targets_store_meta() reads name and error metadata",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble(
        field_count = base::length(fields),
        complete_only = complete_only,
        store = store
      )
    }

    res <-
      read_targets_store_meta(
        store_path = "store",
        meta_fn = fake_meta
      )

    testthat::expect_identical(
      dplyr::pull(res, field_count),
      2L
    )
    testthat::expect_false(dplyr::pull(res, complete_only))
    testthat::expect_identical(dplyr::pull(res, store), "store")
  }
)

testthat::test_that(
  "read_targets_store_meta() returns NULL when metadata read fails",
  {
    fake_meta <- function(fields, complete_only, store) {
      base::stop("cannot read")
    }

    res <-
      read_targets_store_meta(
        store_path = "store",
        meta_fn = fake_meta
      )

    testthat::expect_null(res)
  }
)

testthat::test_that(
  "read_targets_store_meta() validates arguments",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble()
    }

    testthat::expect_error(
      read_targets_store_meta(
        store_path = character(),
        meta_fn = fake_meta
      ),
      regexp = "store_path"
    )
  }
)

testthat::test_that(
  "read_target_meta_or_empty() reads metadata fields",
  {
    fake_meta <-
      function(fields, complete_only, store) {
        tibble::tibble(
          name = "target_a",
          error = NA_character_,
          field_count = base::length(fields),
          complete_only = complete_only,
          store = store
        )
      }

    res <-
      read_target_meta_or_empty(
        store_path = "store_path",
        meta_fn = fake_meta
      )

    testthat::expect_identical(
      dplyr::pull(res, field_count),
      2L
    )
    testthat::expect_false(dplyr::pull(res, complete_only))
    testthat::expect_identical(dplyr::pull(res, store), "store_path")
  }
)

testthat::test_that(
  "read_target_meta_or_empty() returns empty tibble on failure",
  {
    fake_meta <-
      function(fields, complete_only, store) {
        base::stop("cannot read metadata")
      }

    res <-
      read_target_meta_or_empty(
        store_path = "store_path",
        meta_fn = fake_meta
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_identical(base::nrow(res), 0L)
    testthat::expect_named(res, c("name", "error"))
  }
)

testthat::test_that(
  "endpoint diagnosis requires readable hashed targets",
  {
    data_metadata <-
      tibble::tibble(
        name = base::c("folds_genus", "folds_family"),
        error = base::c(NA_character_, NA_character_),
        data = base::c("hash_a", "hash_b")
      )

    res <-
      diagnose_sjsdm_cv_preparation_endpoints(
        store_path = "store",
        target_names = base::c("folds_genus", "folds_family"),
        load_metadata_function = function(...) data_metadata,
        read_target_function = function(name, store) {
          base::list(name = name, store = store)
        }
      )

    testthat::expect_identical(
      res[["endpoint_status"]],
      base::c("prepared", "prepared")
    )
    testthat::expect_identical(
      res[["data_hash"]],
      base::c("hash_a", "hash_b")
    )
  }
)
testthat::test_that(
  "endpoint diagnosis distinguishes missing and errored metadata",
  {
    data_metadata <-
      tibble::tibble(
        name = base::c("folds_family", "folds_ft"),
        error = base::c("upstream failed", NA_character_),
        data = base::c(NA_character_, NA_character_)
      )

    res <-
      diagnose_sjsdm_cv_preparation_endpoints(
        store_path = "store",
        target_names = base::c(
          "folds_genus",
          "folds_family",
          "folds_ft"
        ),
        load_metadata_function = function(...) data_metadata,
        read_target_function = function(...) TRUE
      )

    testthat::expect_identical(
      res[["endpoint_status"]],
      base::c("missing", "errored", "missing")
    )
  }
)

testthat::test_that(
  "endpoint diagnosis identifies legacy qs and other read failures",
  {
    data_metadata <-
      tibble::tibble(
        name = base::c("folds_genus", "folds_family"),
        error = base::c(NA_character_, NA_character_),
        data = base::c("hash_a", "hash_b")
      )

    res <-
      diagnose_sjsdm_cv_preparation_endpoints(
        store_path = "store",
        target_names = base::c("folds_genus", "folds_family"),
        load_metadata_function = function(...) data_metadata,
        read_target_function = function(name, ...) {
          if (
            name == "folds_genus"
          ) {
            base::stop("there is no package called 'qs'")
          }
          base::stop("checksum mismatch")
        }
      )

    testthat::expect_identical(
      res[["endpoint_status"]],
      base::c("cache_format_incompatible", "unreadable")
    )
  }
)

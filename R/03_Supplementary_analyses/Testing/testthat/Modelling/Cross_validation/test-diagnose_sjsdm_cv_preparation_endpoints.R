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
        file_exists_function = function(...) TRUE,
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

testthat::test_that("absent objects are not legacy cache incompatibility", {
  for (
    flag_metadata_error in base::c(TRUE, FALSE)
  ) {
    res <-
      diagnose_sjsdm_cv_preparation_endpoints(
        store_path = "store", target_names = "folds_genus",
        load_metadata_function = function(...) tibble::tibble(
          name = "folds_genus", data = "old_hash",
          error = if (
            flag_metadata_error
          ) {
            "there is no package called 'qs'"
          } else {
            NA_character_
          }),
        file_exists_function = function(...) FALSE,
        read_target_function = function(...) {
          base::stop("there is no package called 'qs'")
        }
      )
    testthat::expect_false(
      res[["endpoint_status"]] == "cache_format_incompatible")
    testthat::expect_match(res[["error_message"]], "absent|missing")
  }
})

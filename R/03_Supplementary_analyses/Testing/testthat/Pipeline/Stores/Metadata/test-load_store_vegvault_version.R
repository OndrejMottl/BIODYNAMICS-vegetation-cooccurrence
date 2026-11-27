testthat::test_that(
  "load_store_vegvault_version() returns the recorded version",
  {
    data_meta <-
      tibble::tibble(
        name = base::c("config_vegvault_release", "data_vegvault_extracted"),
        error = NA_character_
      )

    res <-
      load_store_vegvault_version(
        store_path = "store",
        data_meta = data_meta,
        read_target_fn = function(name, store) {
          tibble::tibble(
            vegvault_version = "2.0.0",
            git_commit = "f19d588",
            manifest_sha256 = "hash_accepted"
          )
        }
      )

    testthat::expect_identical(res, "2.0.0")
  }
)

testthat::test_that(
  "load_store_vegvault_version() gives NA without a successful record",
  {
    res_absent <-
      load_store_vegvault_version(
        store_path = "store",
        data_meta = tibble::tibble(
          name = "data_vegvault_extracted",
          error = NA_character_
        ),
        read_target_fn = function(...) {
          base::stop("The target should not be read.")
        }
      )

    res_errored <-
      load_store_vegvault_version(
        store_path = "store",
        data_meta = tibble::tibble(
          name = "config_vegvault_release",
          error = "version mismatch"
        ),
        read_target_fn = function(...) {
          base::stop("The target should not be read.")
        }
      )

    res_without_metadata <-
      load_store_vegvault_version(
        store_path = "store",
        data_meta = NULL,
        read_target_fn = function(...) {
          base::stop("The target should not be read.")
        }
      )

    testthat::expect_identical(res_absent, NA_character_)
    testthat::expect_identical(res_errored, NA_character_)
    testthat::expect_identical(res_without_metadata, NA_character_)
  }
)

testthat::test_that(
  "load_store_vegvault_version() stops on a malformed release record",
  {
    testthat::expect_error(
      load_store_vegvault_version(
        store_path = "store",
        data_meta = tibble::tibble(
          name = "config_vegvault_release",
          error = NA_character_
        ),
        read_target_fn = function(...) {
          tibble::tibble(version = "2.0.0")
        }
      ),
      regexp = "vegvault_version"
    )
  }
)

testthat::test_that(
  "load_store_vegvault_version() validates its arguments",
  {
    testthat::expect_error(
      load_store_vegvault_version(
        store_path = 1,
        data_meta = NULL
      ),
      regexp = "store_path"
    )

    testthat::expect_error(
      load_store_vegvault_version(
        store_path = "store",
        data_meta = NULL,
        read_target_fn = "tar_read_raw"
      ),
      regexp = "read_target_fn"
    )
  }
)

testthat::test_that(
  "load_targets_target_fingerprints() returns ordered hashes",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble(
        name = base::c("target_b", "target_a"),
        data = base::c("hash_b", "hash_a"),
        error = base::c(NA_character_, NA_character_)
      )
    }

    data_fingerprints <-
      load_targets_target_fingerprints(
        store_path = "store",
        target_names = base::c("target_b", "target_a"),
        meta_fn = fake_meta
      )

    testthat::expect_identical(
      dplyr::pull(data_fingerprints, "name"),
      base::c("target_a", "target_b")
    )
    testthat::expect_identical(
      dplyr::pull(data_fingerprints, "data_hash"),
      base::c("hash_a", "hash_b")
    )
  }
)


testthat::test_that(
  "load_targets_target_fingerprints() fails on missing targets",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble(
        name = "target_a",
        data = "hash_a",
        error = NA_character_
      )
    }

    testthat::expect_error(
      load_targets_target_fingerprints(
        store_path = "store",
        target_names = base::c("target_a", "target_b"),
        meta_fn = fake_meta
      ),
      regexp = "target_b"
    )
  }
)


testthat::test_that(
  "load_targets_target_fingerprints() fails on duplicate metadata",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble(
        name = base::c("target_a", "target_a"),
        data = base::c("hash_a", "hash_a"),
        error = base::c(NA_character_, NA_character_)
      )
    }

    testthat::expect_error(
      load_targets_target_fingerprints(
        store_path = "store",
        target_names = "target_a",
        meta_fn = fake_meta
      ),
      regexp = "exactly once"
    )
  }
)


testthat::test_that(
  "load_targets_target_fingerprints() fails on errored targets",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble(
        name = "target_a",
        data = "hash_a",
        error = "failed"
      )
    }

    testthat::expect_error(
      load_targets_target_fingerprints(
        store_path = "store",
        target_names = "target_a",
        meta_fn = fake_meta
      ),
      regexp = "errored"
    )
  }
)


testthat::test_that(
  "load_targets_target_fingerprints() fails on missing hashes",
  {
    fake_meta <- function(fields, complete_only, store) {
      tibble::tibble(
        name = "target_a",
        data = NA_character_,
        error = NA_character_
      )
    }

    testthat::expect_error(
      load_targets_target_fingerprints(
        store_path = "store",
        target_names = "target_a",
        meta_fn = fake_meta
      ),
      regexp = "data hash"
    )
  }
)


testthat::test_that(
  "load_targets_target_fingerprints() validates target names",
  {
    testthat::expect_error(
      load_targets_target_fingerprints(
        store_path = "store",
        target_names = base::c("target_a", "target_a")
      ),
      regexp = "target_names"
    )
  }
)

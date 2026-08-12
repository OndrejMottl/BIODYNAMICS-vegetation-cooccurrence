testthat::test_that(
  "load_targets_target_by_fingerprint() reads the expected target",
  {
    data_fingerprint <-
      tibble::tibble(
        name = "target_a",
        data_hash = "hash_a"
      )

    fake_read <- function(name, store) {
      base::list(name = name, store = store)
    }

    list_target <-
      load_targets_target_by_fingerprint(
        store_path = "store",
        target_name = "target_a",
        data_fingerprint = data_fingerprint,
        read_fn = fake_read
      )

    testthat::expect_identical(
      purrr::chuck(list_target, "name"),
      "target_a"
    )
    testthat::expect_identical(
      purrr::chuck(list_target, "store"),
      "store"
    )
  }
)


testthat::test_that(
  "load_targets_target_by_fingerprint() rejects mismatched fingerprints",
  {
    data_fingerprint <-
      tibble::tibble(
        name = "target_b",
        data_hash = "hash_b"
      )

    testthat::expect_error(
      load_targets_target_by_fingerprint(
        store_path = "store",
        target_name = "target_a",
        data_fingerprint = data_fingerprint,
        read_fn = base::identity
      ),
      regexp = "target_a"
    )
  }
)

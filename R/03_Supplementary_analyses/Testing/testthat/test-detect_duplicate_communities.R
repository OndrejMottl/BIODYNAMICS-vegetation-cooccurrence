testthat::test_that(
  "detect_duplicate_communities() validates inputs",
  {
    testthat::expect_error(
      detect_duplicate_communities(data_source = NULL),
      regexp = "data_source"
    )

    data_missing <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      detect_duplicate_communities(
        data_source = data_missing
      ),
      regexp = "taxon"
    )
  }
)


testthat::test_that(
  "detect_duplicate_communities() returns zero rows for unique records",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b", "site_b"),
      sample_name = c("s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0),
      taxon = c("Abies", "Betula", "Abies", "Betula"),
      pollen_count = c(1, 2, 1, 3)
    )

    res <- detect_duplicate_communities(
      data_source = data_community
    )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_named(
      res,
      c(
        "duplicate_community_group",
        "dataset_name",
        "sample_name",
        "age",
        "community_signature",
        "n_records"
      )
    )
  }
)


testthat::test_that(
  "detect_duplicate_communities() detects sorted exact signatures",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_b", "site_b", "site_a", "site_a"),
      sample_name = c("s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0),
      taxon = c("Betula", "Abies", "Abies", "Betula"),
      pollen_count = c(2, 1, 1, 2)
    )

    res <- detect_duplicate_communities(
      data_source = data_community
    )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      dplyr::pull(res, dataset_name),
      c("site_a", "site_b")
    )
    testthat::expect_equal(dplyr::pull(res, n_records), c(2L, 2L))
  }
)

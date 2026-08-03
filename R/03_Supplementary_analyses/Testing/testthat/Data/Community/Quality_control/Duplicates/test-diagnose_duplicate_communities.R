testthat::test_that(
  "diagnose_duplicate_communities() validates inputs",
  {
    testthat::expect_error(
      diagnose_duplicate_communities(data_community = NULL),
      regexp = "data_source"
    )

    data_community_missing_columns <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      diagnose_duplicate_communities(
        data_community = data_community_missing_columns
      ),
      regexp = "taxon"
    )
  }
)


testthat::test_that(
  "diagnose_duplicate_communities() returns zero rows for unique records",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b", "site_b"),
      sample_name = c("s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0),
      taxon = c("Abies", "Betula", "Abies", "Betula"),
      pollen_count = c(1, 2, 1, 3)
    )

    res_duplicate_communities <- diagnose_duplicate_communities(
      data_community = data_community
    )

    testthat::expect_s3_class(res_duplicate_communities, "tbl_df")
    testthat::expect_equal(base::nrow(res_duplicate_communities), 0L)
    testthat::expect_named(
      res_duplicate_communities,
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
  "diagnose_duplicate_communities() detects sorted exact signatures",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_b", "site_b", "site_a", "site_a"),
      sample_name = c("s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0),
      taxon = c("Betula", "Abies", "Abies", "Betula"),
      pollen_count = c(2, 1, 1, 2)
    )

    res_duplicate_communities <- diagnose_duplicate_communities(
      data_community = data_community
    )

    testthat::expect_equal(base::nrow(res_duplicate_communities), 2L)
    testthat::expect_equal(
      dplyr::pull(res_duplicate_communities, dataset_name),
      c("site_a", "site_b")
    )
    testthat::expect_equal(
      dplyr::pull(res_duplicate_communities, n_records),
      c(2L, 2L)
    )
  }
)

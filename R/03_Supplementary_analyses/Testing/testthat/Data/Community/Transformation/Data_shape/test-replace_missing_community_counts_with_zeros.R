testthat::test_that(
  "replace_missing_community_counts_with_zeros() replaces missing counts",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset1"),
        sample_name = base::c("sample1", "sample2"),
        taxon1 = base::c(NA_real_, 20),
        taxon2 = base::c(30, NA_real_)
      )

    res_community_complete <-
      replace_missing_community_counts_with_zeros(
        data_community = data_community
      )

    testthat::expect_s3_class(
      res_community_complete,
      "data.frame"
    )
    testthat::expect_named(
      res_community_complete,
      base::c("dataset_name", "sample_name", "taxon1", "taxon2")
    )
    testthat::expect_equal(
      dplyr::pull(res_community_complete, dataset_name),
      base::c("dataset1", "dataset1")
    )
    testthat::expect_equal(
      dplyr::pull(res_community_complete, taxon1),
      base::c(0, 20)
    )
    testthat::expect_equal(
      dplyr::pull(res_community_complete, taxon2),
      base::c(30, 0)
    )
  }
)

testthat::test_that(
  "replace_missing_community_counts_with_zeros() validates its input contract",
  {
    testthat::expect_error(
      replace_missing_community_counts_with_zeros(
        data_community = NULL
      ),
      "must be a data frame"
    )
    testthat::expect_error(
      replace_missing_community_counts_with_zeros(
        data_community = tibble::tibble(
          dataset_name = "dataset1",
          sample_name = "sample1"
        )
      ),
      "at least one taxon column"
    )
    testthat::expect_error(
      replace_missing_community_counts_with_zeros(
        data_community = tibble::tibble(
          dataset_name = "dataset1",
          sample_name = "sample1",
          taxon1 = "missing"
        )
      ),
      "must be numeric"
    )
  }
)

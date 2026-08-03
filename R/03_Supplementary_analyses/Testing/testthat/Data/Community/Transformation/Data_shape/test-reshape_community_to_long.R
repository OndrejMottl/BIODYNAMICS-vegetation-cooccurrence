testthat::test_that(
  "reshape_community_to_long() pivots taxon counts and omits missing values",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset1"),
        sample_name = base::c("sample1", "sample2"),
        taxon1 = base::c(10, 20),
        taxon2 = base::c(30, NA_real_)
      )

    res_community_long <-
      reshape_community_to_long(data_community = data_community)

    testthat::expect_s3_class(
      res_community_long,
      "data.frame"
    )
    testthat::expect_named(
      res_community_long,
      base::c(
        "dataset_name",
        "sample_name",
        "taxon",
        "pollen_count"
      )
    )
    testthat::expect_equal(
      base::nrow(res_community_long),
      3L
    )
    testthat::expect_equal(
      dplyr::pull(res_community_long, pollen_count),
      base::c(10, 30, 20)
    )
  }
)

testthat::test_that(
  "reshape_community_to_long() validates its input contract",
  {
    testthat::expect_error(
      reshape_community_to_long(data_community = NULL),
      "must be a data frame"
    )
    testthat::expect_error(
      reshape_community_to_long(data_community = 123),
      "must be a data frame"
    )
    testthat::expect_error(
      reshape_community_to_long(
        data_community = tibble::tibble(
          dataset_name = "dataset1",
          sample_name = "sample1"
        )
      ),
      "at least one taxon column"
    )
  }
)

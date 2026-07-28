testthat::test_that(
  "summarise_pollen_counts_by_sample() returns a data frame",
  {
    data_community <-
      tibble::tibble(
        sample_name = c(
          "sample1", "sample1", "sample2"
        ),
        pollen_count = c(10, 20, 30)
      )

    res_pollen_sums <-
      summarise_pollen_counts_by_sample(
        data_community = data_community
      )

    testthat::expect_s3_class(res_pollen_sums, "data.frame")
  }
)

testthat::test_that(
  "summarise_pollen_counts_by_sample() validates input",
  {
    testthat::expect_error(
      summarise_pollen_counts_by_sample(data_community = NULL),
      regexp = "data_community"
    )
    testthat::expect_error(
      summarise_pollen_counts_by_sample(data_community = 123),
      regexp = "data_community"
    )
  }
)

testthat::test_that(
  "summarise_pollen_counts_by_sample() returns totals",
  {
    data_community <-
      tibble::tibble(
        sample_name = c(
          "sample1", "sample1", "sample2"
        ),
        pollen_count = c(10, 20, 30)
      )

    res_pollen_sums <-
      summarise_pollen_counts_by_sample(
        data_community = data_community
      )

    testthat::expect_equal(
      base::colnames(res_pollen_sums),
      c(
        "sample_name",
        "pollen_sum"
      )
    )

    testthat::expect_equal(
      res_pollen_sums[["pollen_sum"]],
      c(30, 30)
    )

    testthat::expect_equal(
      base::nrow(res_pollen_sums),
      2
    )
  }
)

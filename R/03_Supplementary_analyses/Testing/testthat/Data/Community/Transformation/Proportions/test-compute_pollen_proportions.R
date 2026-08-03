testthat::test_that("compute_pollen_proportions() returns a data frame", {
  data_community <-
    tibble::tibble(
      sample_name = rep(
        c(
          "sample1", "sample2", "sample3", "sample4", "sample5"
        ),
        each = 2
      ),
      taxon = rep(
        c(
          "taxon1", "taxon2"
        ),
        5
      ),
      pollen_count = rep(
        seq(1, 10, by = 2),
        2
      )
    )

  data_pollen_sums <-
    summarise_pollen_counts_by_sample(
      data_community = data_community
    )

  res_pollen_proportions <-
    compute_pollen_proportions(
      data_community = data_community,
      data_pollen_sums = data_pollen_sums
    )

  testthat::expect_s3_class(res_pollen_proportions, "data.frame")
})

testthat::test_that("compute_pollen_proportions() validates inputs", {
  testthat::expect_error(
    compute_pollen_proportions(
      data_community = NULL,
      data_pollen_sums = NULL
    ),
    regexp = "data_community"
  )
  testthat::expect_error(
    compute_pollen_proportions(
      data_community = 123,
      data_pollen_sums = 456
    ),
    regexp = "data_community"
  )
})

testthat::test_that("compute_pollen_proportions() returns expected values", {
  data_community <-
    tibble::tibble(
      sample_name = rep(
        c(
          "sample1", "sample2", "sample3", "sample4", "sample5"
        ),
        each = 2
      ),
      taxon = rep(
        c(
          "taxon1", "taxon2"
        ),
        5
      ),
      pollen_count = rep(
        seq(1, 10, by = 2),
        2
      )
    )

  data_pollen_sums <-
    summarise_pollen_counts_by_sample(
      data_community = data_community
    )

  res_pollen_proportions <-
    compute_pollen_proportions(
      data_community = data_community,
      data_pollen_sums = data_pollen_sums
    )

  testthat::expect_equal(
    base::colnames(res_pollen_proportions),
    c("sample_name", "taxon", "value")
  )

  testthat::expect_equal(
    dplyr::pull(res_pollen_proportions, value),
    c(
      data_community[["pollen_count"]] /
        rep(
          data_pollen_sums[["pollen_sum"]],
          each = 2
        )
    )
  )
})

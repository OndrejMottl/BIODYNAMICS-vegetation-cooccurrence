#----------------------------------------------------------#
# Helper data -----
#----------------------------------------------------------#

data_example_counts <-
  tibble::tibble(
    dataset_name = rep("dataset1", 6),
    sample_name = rep(c("s1", "s2", "s3"), each = 2),
    taxon = rep(c("taxon1", "taxon2"), 3),
    age = rep(c(100, 500, 1000), each = 2),
    pollen_count = c(3, 7, 2, 8, 5, 5)
  )


#----------------------------------------------------------#
# Output type tests -----
#----------------------------------------------------------#

testthat::test_that(
  "make_community_proportions() returns a data frame",
  {
    result <- make_community_proportions(data_example_counts)

    testthat::expect_s3_class(result, "data.frame")
  }
)


#----------------------------------------------------------#
# Input error handling tests -----
#----------------------------------------------------------#

testthat::test_that(
  "make_community_proportions() errors on NULL input",
  {
    testthat::expect_error(
      make_community_proportions(NULL),
      regexp = "data frame"
    )
  }
)

testthat::test_that(
  "make_community_proportions() errors when pollen_count column is missing",
  {
    data_no_count <-
      tibble::tibble(
        dataset_name = "dataset1",
        sample_name = "s1",
        taxon = "taxon1",
        age = 100,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      make_community_proportions(data_no_count),
      regexp = "pollen_count"
    )
  }
)


#----------------------------------------------------------#
# Functional correctness tests -----
#----------------------------------------------------------#

testthat::test_that(
  "make_community_proportions() returns pollen_prop column",
  {
    result <- make_community_proportions(data_example_counts)

    testthat::expect_true("pollen_prop" %in% colnames(result))
  }
)

testthat::test_that(
  "make_community_proportions() drops pollen_count column",
  {
    result <- make_community_proportions(data_example_counts)

    testthat::expect_false("pollen_count" %in% colnames(result))
  }
)

testthat::test_that(
  "make_community_proportions() proportions sum to 1 within each sample",
  {
    result <- make_community_proportions(data_example_counts)

    sample_sums <-
      result |>
      dplyr::group_by(sample_name) |>
      dplyr::summarise(
        total = sum(pollen_prop),
        .groups = "drop"
      )

    testthat::expect_true(
      all(abs(sample_sums$total - 1) < 1e-10)
    )
  }
)

testthat::test_that(
  "make_community_proportions() returns correct proportion values",
  {
    result <- make_community_proportions(data_example_counts)

    # sample s1: taxon1=3, taxon2=7, total=10 -> 0.3 and 0.7
    prop_s1 <-
      result |>
      dplyr::filter(sample_name == "s1") |>
      dplyr::arrange(taxon) |>
      dplyr::pull(pollen_prop)

    testthat::expect_equal(prop_s1, c(0.3, 0.7))
  }
)

testthat::test_that(
  "make_community_proportions() preserves row count",
  {
    result <- make_community_proportions(data_example_counts)

    testthat::expect_equal(nrow(result), nrow(data_example_counts))
  }
)

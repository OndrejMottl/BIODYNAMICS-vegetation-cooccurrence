#----------------------------------------------------------#
# Helper data -----
#----------------------------------------------------------#

data_community_counts <-
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
  "prepare_community_proportions() returns a data frame",
  {
    res_community_proportions <-
      prepare_community_proportions(
        data_community = data_community_counts
      )

    testthat::expect_s3_class(res_community_proportions, "data.frame")
  }
)


#----------------------------------------------------------#
# Input error handling tests -----
#----------------------------------------------------------#

testthat::test_that(
  "prepare_community_proportions() errors on NULL input",
  {
    testthat::expect_error(
      prepare_community_proportions(data_community = NULL),
      regexp = "data frame"
    )
  }
)

testthat::test_that(
  "prepare_community_proportions() requires pollen_count",
  {
    data_community_without_counts <-
      tibble::tibble(
        dataset_name = "dataset1",
        sample_name = "s1",
        taxon = "taxon1",
        age = 100,
        value = 0.5
      )

    testthat::expect_error(
      prepare_community_proportions(
        data_community = data_community_without_counts
      ),
      regexp = "pollen_count"
    )
  }
)


#----------------------------------------------------------#
# Functional correctness tests -----
#----------------------------------------------------------#

testthat::test_that(
  "prepare_community_proportions() returns value column",
  {
    res_community_proportions <-
      prepare_community_proportions(
        data_community = data_community_counts
      )

    testthat::expect_true(
      "value" %in% base::colnames(res_community_proportions)
    )
  }
)

testthat::test_that(
  "prepare_community_proportions() drops pollen_count column",
  {
    res_community_proportions <-
      prepare_community_proportions(
        data_community = data_community_counts
      )

    testthat::expect_false(
      "pollen_count" %in% base::colnames(res_community_proportions)
    )
  }
)

testthat::test_that(
  "prepare_community_proportions() sums to 1 within each sample",
  {
    res_community_proportions <-
      prepare_community_proportions(
        data_community = data_community_counts
      )

    data_sample_proportion_sums <-
      res_community_proportions |>
      dplyr::group_by(sample_name) |>
      dplyr::summarise(
        total = sum(value),
        .groups = "drop"
      )

    testthat::expect_true(
      base::all(
        base::abs(data_sample_proportion_sums[["total"]] - 1) < 1e-10
      )
    )
  }
)

testthat::test_that(
  "prepare_community_proportions() returns correct values",
  {
    res_community_proportions <-
      prepare_community_proportions(
        data_community = data_community_counts
      )

    # sample s1: taxon1=3, taxon2=7, total=10 -> 0.3 and 0.7
    vec_sample_s1_proportions <-
      res_community_proportions |>
      dplyr::filter(sample_name == "s1") |>
      dplyr::arrange(taxon) |>
      dplyr::pull(value)

    testthat::expect_equal(
      vec_sample_s1_proportions,
      base::c(0.3, 0.7)
    )
  }
)

testthat::test_that(
  "prepare_community_proportions() preserves row count",
  {
    res_community_proportions <-
      prepare_community_proportions(
        data_community = data_community_counts
      )

    testthat::expect_equal(
      base::nrow(res_community_proportions),
      base::nrow(data_community_counts)
    )
  }
)

#----------------------------------------------------------#
# Helper data -----
#----------------------------------------------------------#

# Pre-proportioned data — what the function now expects
data_example_proportions <-
  tibble::tibble(
    dataset_name = rep("dataset1", 10),
    taxon = rep(c("taxon1", "taxon2"), 5),
    age = rep(seq(100, 1000, by = 200), each = 2),
    pollen_prop = rep(c(0.4, 0.6), 5)
  )


#----------------------------------------------------------#
# Output type tests -----
#----------------------------------------------------------#

testthat::test_that(
  "interpolate_community_data() returns a data frame",
  {
    result <-
      interpolate_community_data(
        data = data_example_proportions,
        age_min = 0,
        age_max = 1000,
        timestep = 100
      )

    testthat::expect_s3_class(result, "data.frame")
  }
)


#----------------------------------------------------------#
# Input error handling tests -----
#----------------------------------------------------------#

testthat::test_that(
  "interpolate_community_data() errors on NULL input",
  {
    testthat::expect_error(
      interpolate_community_data(NULL)
    )
  }
)

testthat::test_that(
  "interpolate_community_data() errors on non-data-frame input",
  {
    testthat::expect_error(
      interpolate_community_data(123)
    )
  }
)

testthat::test_that(
  "interpolate_community_data() errors when pollen_prop column is missing",
  {
    data_missing_col <-
      tibble::tibble(
        dataset_name = "dataset1",
        taxon = "taxon1",
        age = 100,
        pollen_count = 5
      )

    testthat::expect_error(
      interpolate_community_data(
        data = data_missing_col,
        age_min = 0,
        age_max = 500,
        timestep = 100
      ),
      regexp = "pollen_prop"
    )
  }
)


#----------------------------------------------------------#
# Functional correctness tests -----
#----------------------------------------------------------#

testthat::test_that(
  "interpolate_community_data() returns expected columns",
  {
    result <-
      interpolate_community_data(
        data = data_example_proportions,
        age_min = 0,
        age_max = 1000,
        timestep = 100
      )

    testthat::expect_true(
      all(
        c("dataset_name", "taxon", "age", "pollen_prop") %in%
          colnames(result)
      )
    )

    testthat::expect_false(
      "sample_name" %in% colnames(result)
    )
  }
)

testthat::test_that(
  "interpolate_community_data() produces correct row count",
  {
    result <-
      interpolate_community_data(
        data = data_example_proportions,
        age_min = 0,
        age_max = 1000,
        timestep = 100
      )

    # 11 time points x 2 taxa = 22 rows
    testthat::expect_equal(nrow(result), 22)
  }
)

testthat::test_that(
  "interpolate_community_data() drops NA values outside data range",
  {
    result <-
      interpolate_community_data(
        data = data_example_proportions,
        age_min = 0,
        age_max = 1000,
        timestep = 100
      )

    testthat::expect_equal(
      nrow(tidyr::drop_na(result)),
      18
    )
  }
)

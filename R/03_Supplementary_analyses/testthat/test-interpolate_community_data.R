testthat::test_that("interpolate_community_data returns a data frame", {
  data_example_pollen <-
    tibble::tibble(
      dataset_name = rep("dataset1", 10),
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

  data_example_age <-
    tibble::tibble(
      sample_name = c(
        "sample1", "sample2", "sample3", "sample4", "sample5"
      ),
      age = seq(100, 1000, by = 200),
    )

  data_example <-
    dplyr::left_join(
      data_example_pollen,
      data_example_age,
      by = "sample_name"
    )

  result <-
    interpolate_community_data(
      data = data_example,
      age_min = 0,
      age_max = 1000,
      timestep = 100
    )

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("interpolate_community_data handles invalid input", {
  testthat::expect_error(interpolate_community_data(NULL))
  testthat::expect_error(interpolate_community_data(123))
})

testthat::test_that("interpolate_community_data produces expected results", {
  data_example_pollen <-
    tibble::tibble(
      dataset_name = rep("dataset1", 10),
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

  data_example_age <-
    tibble::tibble(
      sample_name = c(
        "sample1", "sample2", "sample3", "sample4", "sample5"
      ),
      age = seq(100, 1000, by = 200),
    )

  data_example <-
    dplyr::left_join(
      data_example_pollen,
      data_example_age,
      by = "sample_name"
    )

  result <-
    interpolate_community_data(
      data = data_example,
      age_min = 0,
      age_max = 1000,
      timestep = 100
    )


  testthat::expect_true(
    nrow(result) == 22
  )

  testthat::expect_true(
    nrow(tidyr::drop_na(result)) == 18
  )

  testthat::expect_true(
    all(
      c(
        "dataset_name",
        "taxon",
        "age",
        "pollen_prop"
      ) %in% colnames(result)
    )
  )

  testthat::expect_false(
    "sample_name" %in% colnames(result)
  )
})

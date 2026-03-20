testthat::test_that("interpolate_data returns a data frame", {
  data_example <-
    tibble::tibble(
      dataset_name = rep("dataset1", 10),
      taxon = rep(
        c(
          "taxon1", "taxon2"
        ),
        each = 5
      ),
      age = seq(0, 1000, length.out = 10),
      pollen_prop = rep(
        c(0.1, 0.2),
        each = 5
      )
    )

  result <-
    interpolate_data(
      data = data_example,
      age_min = 0,
      age_max = 1000,
      timestep = 100
    )

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("interpolate_data handles invalid input", {
  testthat::expect_error(interpolate_data(NULL))
  testthat::expect_error(interpolate_data(123))
})

testthat::test_that("interpolate_data produces expected results", {
  data_example <-
    tibble::tibble(
      dataset_name = rep("dataset1", 10),
      taxon = rep(
        c(
          "taxon1", "taxon2"
        ),
        each = 5
      ),
      age = seq(100, 1000, by = 100) + 10,
      pollen_prop = rep(
        c(0.1, 0.2),
        each = 5
      )
    )

  result <-
    interpolate_data(
      data = data_example,
      by = c("dataset_name", "taxon"),
      age_min = 0,
      age_max = 1000,
      timestep = 100
    )

  testthat::expect_true("dataset_name" %in% colnames(result))
  testthat::expect_true("taxon" %in% colnames(result))
  testthat::expect_true("age" %in% colnames(result))
  testthat::expect_true("pollen_prop" %in% colnames(result))

  result %>%
    tidyr::drop_na() %>%
    dplyr::pull(age) %>%
    testthat::expect_equal(
      c(200, 300, 400, 500, 700, 800, 900, 1000)
    )

  testthat::expect_equal(base::nrow(result), 22)
})

testthat::test_that("interpolate_data errors when timestep <= 0", {
  data_example <-
    tibble::tibble(
      dataset_name = rep("dataset1", 5),
      age = seq(100, 500, length.out = 5),
      pollen_prop = seq(0.1, 0.5, length.out = 5)
    )

  testthat::expect_error(
    interpolate_data(
      data = data_example,
      age_min = 0,
      age_max = 1000,
      timestep = 0
    ),
    regexp = "timestep"
  )

  testthat::expect_error(
    interpolate_data(
      data = data_example,
      age_min = 0,
      age_max = 1000,
      timestep = -100
    ),
    regexp = "timestep"
  )
})

testthat::test_that("interpolate_data errors when age_min >= age_max", {
  data_example <-
    tibble::tibble(
      dataset_name = rep("dataset1", 5),
      age = seq(100, 500, length.out = 5),
      pollen_prop = seq(0.1, 0.5, length.out = 5)
    )

  testthat::expect_error(
    interpolate_data(
      data = data_example,
      age_min = 1000,
      age_max = 500,
      timestep = 100
    ),
    regexp = "age_min"
  )

  testthat::expect_error(
    interpolate_data(
      data = data_example,
      age_min = 500,
      age_max = 500,
      timestep = 100
    ),
    regexp = "age_min"
  )
})

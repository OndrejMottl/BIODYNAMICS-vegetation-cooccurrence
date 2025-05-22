testthat::test_that("get_coords() return dataframe", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2", "dataset3"),
      coord_long = c(1.0, 2.0, 1.0),
      coord_lat = c(3.0, 4.0, 3.0),
      dataset_type = c("vegetation_plot", "gridpoints", "vegetation_plot")
    )

  res <- get_coords(data_dummy)

  testthat::expect_s3_class(res, "data.frame")
})


testthat::test_that("get_coords() return correct data", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2", "dataset3"),
      coord_long = c(1.0, 2.0, 1.0),
      coord_lat = c(3.0, 4.0, 3.0),
      dataset_type = c("vegetation_plot", "gridpoints", "vegetation_plot")
    )

  res <- get_coords(data_dummy)

  expected_res <-
    data.frame(
      dataset_name = c("dataset1", "dataset3"),
      coord_long = c(1.0, 1.0),
      coord_lat = c(3.0, 3.0)
    ) %>%
    tibble::column_to_rownames("dataset_name")

  testthat::expect_equal(
    res,
    expected_res
  )
})

testthat::test_that("get_coords() handles empty data", {
  data_dummy <-
    data.frame(
      dataset_name = character(),
      coord_long = numeric(),
      coord_lat = numeric(),
      dataset_type = character()
    )

  res <- get_coords(data_dummy)

  expected_res <-
    data.frame(
      dataset_name = character(),
      coord_long = numeric(),
      coord_lat = numeric()
    ) %>%
    tibble::column_to_rownames("dataset_name")

  testthat::expect_equal(
    res,
    expected_res
  )
})

testthat::test_that("get_coords() with wrong argument", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2", "dataset3"),
      coord_long = c(1.0, 2.0, 1.0),
      coord_lat = c(3.0, 4.0, 3.0),
      dataset_type = c("vegetation_plot", "gridpoints", "vegetation_plot")
    )

  testthat::expect_error(
    get_coords(data = NULL)
  )

  testthat::expect_error(
    get_coords(data = "not a data frame")
  )
})

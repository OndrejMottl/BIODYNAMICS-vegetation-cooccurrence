# Input Validation

testthat::test_that("extract_dataset_coordinates() errors on NULL input", {
  testthat::expect_error(
    extract_dataset_coordinates(data = NULL)
  )
})

testthat::test_that("extract_dataset_coordinates() errors on non-data.frame input", {
  testthat::expect_error(
    extract_dataset_coordinates(data = "not a data frame")
  )
})

testthat::test_that(
  "extract_dataset_coordinates() errors when dataset_type column is missing",
  {
    data_no_type <-
      data.frame(
        dataset_name = c("dataset1", "dataset2"),
        coord_long = c(1.0, 2.0),
        coord_lat = c(3.0, 4.0)
      )

    testthat::expect_error(
      extract_dataset_coordinates(data_no_type)
    )
  }
)

testthat::test_that(
  "extract_dataset_coordinates() errors when dataset_name column is missing",
  {
    data_no_name <-
      data.frame(
        coord_long = c(1.0, 2.0),
        coord_lat = c(3.0, 4.0),
        dataset_type = c("vegetation_plot", "vegetation_plot")
      )

    testthat::expect_error(
      extract_dataset_coordinates(data_no_name)
    )
  }
)

# Output Structure

testthat::test_that("extract_dataset_coordinates() returns a data.frame", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      coord_long = c(1.0, 2.0),
      coord_lat = c(3.0, 4.0),
      dataset_type = c("vegetation_plot", "vegetation_plot")
    )

  res <-
    extract_dataset_coordinates(data_dummy)

  testthat::expect_s3_class(res, "data.frame")
})

testthat::test_that("extract_dataset_coordinates() result has coord_long and coord_lat columns", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      coord_long = c(1.0, 2.0),
      coord_lat = c(3.0, 4.0),
      dataset_type = c("vegetation_plot", "vegetation_plot")
    )

  res <-
    extract_dataset_coordinates(data_dummy)

  testthat::expect_equal(
    base::colnames(res),
    c("coord_long", "coord_lat")
  )
})

testthat::test_that("extract_dataset_coordinates() uses dataset_name as row names", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      coord_long = c(1.0, 2.0),
      coord_lat = c(3.0, 4.0),
      dataset_type = c("vegetation_plot", "vegetation_plot")
    )

  res <-
    extract_dataset_coordinates(data_dummy)

  testthat::expect_equal(
    base::rownames(res),
    c("dataset1", "dataset2")
  )
})

# Functional Correctness

testthat::test_that("extract_dataset_coordinates() excludes gridpoints", {
  data_dummy <-
    data.frame(
      dataset_name = c("dataset1", "dataset2", "dataset3"),
      coord_long = c(1.0, 2.0, 1.0),
      coord_lat = c(3.0, 4.0, 3.0),
      dataset_type = c("vegetation_plot", "gridpoints", "vegetation_plot")
    )

  res <-
    extract_dataset_coordinates(data_dummy)

  expected_res <-
    data.frame(
      dataset_name = c("dataset1", "dataset3"),
      coord_long = c(1.0, 1.0),
      coord_lat = c(3.0, 3.0)
    ) %>%
    tibble::column_to_rownames("dataset_name")

  testthat::expect_equal(res, expected_res)
})

testthat::test_that("extract_dataset_coordinates() deduplicates identical rows", {
  data_dup <-
    data.frame(
      dataset_name = c("dataset1", "dataset1"),
      coord_long = c(1.0, 1.0),
      coord_lat = c(3.0, 3.0),
      dataset_type = c("vegetation_plot", "vegetation_plot")
    )

  res <-
    extract_dataset_coordinates(data_dup)

  testthat::expect_equal(base::nrow(res), 1L)
})

testthat::test_that(
  "extract_dataset_coordinates() returns empty result when all rows are gridpoints",
  {
    data_all_grid <-
      data.frame(
        dataset_name = c("g1", "g2"),
        coord_long = c(1.0, 2.0),
        coord_lat = c(3.0, 4.0),
        dataset_type = c("gridpoints", "gridpoints")
      )

    res <-
      extract_dataset_coordinates(data_all_grid)

    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that("extract_dataset_coordinates() handles empty data", {
  data_empty <-
    data.frame(
      dataset_name = character(),
      coord_long = numeric(),
      coord_lat = numeric(),
      dataset_type = character()
    )

  res <-
    extract_dataset_coordinates(data_empty)

  expected_res <-
    data.frame(
      dataset_name = character(),
      coord_long = numeric(),
      coord_lat = numeric()
    ) %>%
    tibble::column_to_rownames("dataset_name")

  testthat::expect_equal(res, expected_res)
})

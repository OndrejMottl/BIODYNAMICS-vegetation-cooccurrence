testthat::test_that("add_dataset_name_column_from_rownames() returns correct class", {
  data_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000")
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    add_dataset_name_column_from_rownames(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("add_dataset_name_column_from_rownames() returns correct data", {
  data_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000")
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    add_dataset_name_column_from_rownames(data_example)

  expected_result <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000"),
      dataset_name = c("dataset1", "dataset2")
    ) %>%
    tibble::column_to_rownames("row_name")

  testthat::expect_equal(result, expected_result)
})

testthat::test_that("add_dataset_name_column_from_rownames() handles invalid input", {
  testthat::expect_error(
    add_dataset_name_column_from_rownames(NULL)
  )

  testthat::expect_error(
    add_dataset_name_column_from_rownames(123)
  )

  testthat::expect_error(
    add_dataset_name_column_from_rownames(
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      )
    )
  )
})

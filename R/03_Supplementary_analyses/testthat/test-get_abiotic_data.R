testthat::test_that("get_abiotic_data returns a data frame", {
  data_example <-
    tibble::tibble(
      dataset_name = c("dataset1", "dataset2"),
      data_abiotic = list(
        data.frame(
          sample_name = 1:3,
          abiotic_variable_name = c("A", "B", "C"),
          abiotic_value = c(10, 20, 30)
        ),
        data.frame(
          sample_name = 4:6,
          abiotic_variable_name = c("D", "E", "F"),
          abiotic_value = c(40, 50, 60)
        )
      )
    )

  result <-
    get_abiotic_data(data_example)

  testthat::expect_s3_class(result, "data.frame")
})


testthat::test_that("get_abiotic_data produces expected results", {
  data_example <-
    tibble::tibble(
      dataset_name = c("dataset1", "dataset2"),
      data_abiotic = list(
        data.frame(
          sample_name = 1:3,
          abiotic_variable_name = c("A", "B", "C"),
          abiotic_value = c(10, 20, 30)
        ),
        data.frame(
          sample_name = 4:6,
          abiotic_variable_name = c("D", "E", "F"),
          abiotic_value = c(40, 50, 60)
        )
      )
    )

  result <-
    get_abiotic_data(data_example)

  testthat::expect_equal(
    base::colnames(result),
    c("dataset_name", "sample_name", "abiotic_variable_name", "abiotic_value")
  )

  testthat::expect_equal(
    base::nrow(result),
    6
  )
})

testthat::test_that("get_abiotic_data handles invalid input", {
  testthat::expect_error(get_abiotic_data(NULL))
  testthat::expect_error(get_abiotic_data(123))
})

testthat::test_that(
  "get_abiotic_data errors when required columns are missing",
  {
    data_no_dataset_name <-
      tibble::tibble(
        other_col = c("dataset1", "dataset2"),
        data_abiotic = list(
          data.frame(sample_name = 1:3, abiotic_variable_name = "A"),
          data.frame(sample_name = 4:6, abiotic_variable_name = "B")
        )
      )

    testthat::expect_error(
      get_abiotic_data(data_no_dataset_name),
      regexp = "dataset_name"
    )

    data_no_abiotic_col <-
      tibble::tibble(
        dataset_name = c("dataset1", "dataset2"),
        other_col = list(NULL, NULL)
      )

    testthat::expect_error(
      get_abiotic_data(data_no_abiotic_col),
      regexp = "data_abiotic"
    )
  }
)

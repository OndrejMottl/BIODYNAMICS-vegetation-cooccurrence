testthat::test_that("get_sample_ages returns a data frame", {
  data_example <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset2"
      ),
      data_samples = list(
        data.frame(
          sample_name = c(
            "sample1", "sample2"
          ), age = c(100, 200)
        ),
        data.frame(
          sample_name = c(
            "sample3", "sample4"
          ), age = c(300, 400)
        )
      )
    )

  result <-
    get_sample_ages(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("get_sample_ages handles invalid input", {
  testthat::expect_error(get_sample_ages(NULL))
  testthat::expect_error(get_sample_ages(123))
})

testthat::test_that("get_sample_ages produces expected results", {
  data_example <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset2"
      ),
      data_samples = list(
        data.frame(
          sample_name = c(
            "sample1", "sample2"
          ), age = c(100, 200)
        ),
        data.frame(
          sample_name = c(
            "sample3", "sample4"
          ), age = c(300, 400)
        )
      )
    )

  result <-
    get_sample_ages(data_example)

  testthat::expect_equal(
    base::colnames(result),
    c(
      "dataset_name",
      "sample_name",
      "age"
    )
  )

  testthat::expect_equal(
    dplyr::pull(result, age),
    c(100, 200, 300, 400)
  )

  testthat::expect_equal(
    base::nrow(result),
    4
  )
})

testthat::test_that(
  "get_sample_ages errors when required columns are missing",
  {
    data_no_dataset_name <-
      tibble::tibble(
        other_col = c("dataset1", "dataset2"),
        data_samples = list(
          data.frame(sample_name = "s1", age = 100),
          data.frame(sample_name = "s2", age = 200)
        )
      )

    testthat::expect_error(
      get_sample_ages(data_no_dataset_name),
      regexp = "dataset_name"
    )

    data_no_samples_col <-
      tibble::tibble(
        dataset_name = c("dataset1", "dataset2"),
        other_col = list(NULL, NULL)
      )

    testthat::expect_error(
      get_sample_ages(data_no_samples_col),
      regexp = "data_samples"
    )
  }
)

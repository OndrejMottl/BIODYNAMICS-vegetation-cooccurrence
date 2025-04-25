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
    colnames(result),
    c(
      "dataset_name",
      "sample_name",
      "age"
    )
  )

  testthat::expect_equal(
    result$age,
    c(100, 200, 300, 400)
  )

  testthat::expect_equal(
    nrow(result),
    4
  )
})

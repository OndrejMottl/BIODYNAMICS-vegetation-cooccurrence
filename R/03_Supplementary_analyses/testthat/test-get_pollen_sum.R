testthat::test_that("get_pollen_sum returns a data frame", {
  data_example <-
    tibble::tibble(
      sample_name = c(
        "sample1", "sample1", "sample2"
      ),
      pollen_count = c(10, 20, 30)
    )

  result <-
    get_pollen_sum(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("get_pollen_sum handles invalid input", {
  testthat::expect_error(get_pollen_sum(NULL))
  testthat::expect_error(get_pollen_sum(123))
})

testthat::test_that("get_pollen_sum produces expected results", {
  data_example <-
    tibble::tibble(
      sample_name = c(
        "sample1", "sample1", "sample2"
      ),
      pollen_count = c(10, 20, 30)
    )

  result <-
    get_pollen_sum(data_example)

  testthat::expect_equal(
    colnames(result),
    c(
      "sample_name",
      "pollen_sum"
    )
  )

  testthat::expect_equal(
    result$pollen_sum,
    c(30, 30)
  )

  testthat::expect_equal(
    nrow(result),
    2
  )
})

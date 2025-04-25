testthat::test_that("make_community_data_long returns a data frame", {
  data_example <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      taxon1 = c(10, 20),
      taxon2 = c(30, 40)
    )

  result <-
    make_community_data_long(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("make_community_data_long handles invalid input", {
  testthat::expect_error(make_community_data_long(NULL))
  testthat::expect_error(make_community_data_long(123))
})

testthat::test_that("make_community_data_long produces expected results", {
  data_example <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      taxon1 = c(10, 20),
      taxon2 = c(30, 40)
    )

  result <-
    make_community_data_long(data_example)

  testthat::expect_equal(
    colnames(result),
    c(
      "dataset_name",
      "sample_name",
      "taxon",
      "pollen_count"
    )
  )

  testthat::expect_equal(
    nrow(result),
    4
  )

  testthat::expect_equal(
    result$pollen_count,
    c(10, 30, 20, 40)
  )
})

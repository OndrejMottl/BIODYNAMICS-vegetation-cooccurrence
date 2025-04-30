testthat::test_that("add_age_to_samples returns a data frame", {
  data_community <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      taxon1 = c(10, 20)
    )

  data_ages <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      age = c(100, 200)
    )

  result <-
    add_age_to_samples(data_community, data_ages)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("add_age_to_samples handles invalid input", {
  testthat::expect_error(add_age_to_samples(NULL, NULL))
  testthat::expect_error(add_age_to_samples(123, 456))
})

testthat::test_that("add_age_to_samples produces expected results", {
  data_community <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      taxon1 = c(10, 20)
    )

  data_ages <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      age = c(100, 200)
    )

  result <-
    add_age_to_samples(data_community, data_ages)

  testthat::expect_equal(
    colnames(result),
    c(
      "dataset_name",
      "sample_name",
      "taxon1",
      "age"
    )
  )

  testthat::expect_equal(
    result$age,
    c(100, 200)
  )
})

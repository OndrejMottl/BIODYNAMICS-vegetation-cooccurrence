testthat::test_that("replace_na_community_data_with_zeros returns a data frame", {
  data_example <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      taxon1 = c(NA, 20),
      taxon2 = c(30, NA)
    )

  result <-
    replace_na_community_data_with_zeros(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("replace_na_community_data_with_zeros handles invalid input", {
  testthat::expect_error(replace_na_community_data_with_zeros(NULL))
  testthat::expect_error(replace_na_community_data_with_zeros(123))
})

testthat::test_that("replace_na_community_data_with_zeros produces expected results", {
  data_example <-
    tibble::tibble(
      dataset_name = c(
        "dataset1", "dataset1"
      ),
      sample_name = c(
        "sample1", "sample2"
      ),
      taxon1 = c(NA, 20),
      taxon2 = c(30, NA)
    )

  result <-
    replace_na_community_data_with_zeros(data_example)

  testthat::expect_equal(
    colnames(result),
    c(
      "dataset_name",
      "sample_name",
      "taxon1",
      "taxon2"
    )
  )

  testthat::expect_equal(
    result$taxon1,
    c(0, 20)
  )

  testthat::expect_equal(
    result$taxon2,
    c(30, 0)
  )
})

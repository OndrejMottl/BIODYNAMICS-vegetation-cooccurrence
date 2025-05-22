testthat::test_that("get_dataset_name_from_string() returns correct class", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_dataset_name_from_string(vec_names)

  testthat::expect_equal(class(result), "character")
})


testthat::test_that("get_dataset_name_from_string() returns correct values", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_dataset_name_from_string(vec_names)

  expected_result <-
    c("dataset1", "dataset2", "dataset3")

  testthat::expect_equal(result, expected_result)
})


testthat::test_that("get_dataset_name_from_string() handles invalid input", {
  testthat::expect_error(
    get_dataset_name_from_string(NULL)
  )

  testthat::expect_error(
    get_dataset_name_from_string(character())
  )

  testthat::expect_error(
    get_dataset_name_from_string(c("dataset1"))
  )

  testthat::expect_error(
    get_dataset_name_from_string(c("dataset1", NA))
  )

  testthat::expect_error(
    get_dataset_name_from_string(123)
  )
})

# Input Validation

testthat::test_that("get_dataset_name_from_string() errors on NULL input", {
  testthat::expect_error(
    get_dataset_name_from_string(NULL),
    regexp = "character"
  )
})

testthat::test_that("get_dataset_name_from_string() errors on numeric input", {
  testthat::expect_error(
    get_dataset_name_from_string(123),
    regexp = "character"
  )
})

testthat::test_that("get_dataset_name_from_string() errors on empty vector", {
  testthat::expect_error(
    get_dataset_name_from_string(base::character()),
    regexp = "empty"
  )
})

testthat::test_that("get_dataset_name_from_string() errors when __ is missing", {
  testthat::expect_error(
    get_dataset_name_from_string(c("dataset1__500", "no_separator")),
    regexp = "__"
  )
})

testthat::test_that(
  "get_dataset_name_from_string() errors on single missing __",
  {
    testthat::expect_error(
      get_dataset_name_from_string(c("noseparator")),
      regexp = "__"
    )
  }
)

# Output Structure

testthat::test_that("get_dataset_name_from_string() returns character type", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_dataset_name_from_string(vec_names)

  testthat::expect_type(result, "character")
})

testthat::test_that(
  "get_dataset_name_from_string() output length equals input length",
  {
    vec_names <-
      c("dataset1__500", "dataset2__750", "dataset3__1000")

    result <-
      get_dataset_name_from_string(vec_names)

    testthat::expect_length(result, base::length(vec_names))
  }
)

# Functional Correctness

testthat::test_that("get_dataset_name_from_string() returns correct values", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_dataset_name_from_string(vec_names)

  expected_result <-
    c("dataset1", "dataset2", "dataset3")

  testthat::expect_equal(result, expected_result)
})

testthat::test_that(
  "get_dataset_name_from_string() handles single-element input",
  {
    vec_single <-
      c("mysite__750")

    result <-
      get_dataset_name_from_string(vec_single)

    testthat::expect_equal(result, "mysite")
  }
)

testthat::test_that(
  "get_dataset_name_from_string() handles names with underscores",
  {
    vec_names <-
      c("my_site__100", "another_dataset__200")

    result <-
      get_dataset_name_from_string(vec_names)

    testthat::expect_equal(result, c("my_site", "another_dataset"))
  }
)

testthat::test_that(
  "get_dataset_name_from_string() extracts everything before last __",
  {
    vec_names <-
      c("site__a__b", "dataset__1000__old")

    result <-
      get_dataset_name_from_string(vec_names)

    testthat::expect_equal(result, c("site__a", "dataset__1000"))
  }
)

testthat::test_that("get_dataset_name_from_string() trims whitespace", {
  vec_names <-
    c("  my_site  __100")

  result <-
    get_dataset_name_from_string(vec_names)

  testthat::expect_equal(result, "my_site")
})

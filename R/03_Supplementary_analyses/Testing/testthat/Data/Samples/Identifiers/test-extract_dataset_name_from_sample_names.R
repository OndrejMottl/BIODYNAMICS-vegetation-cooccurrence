# Input Validation

testthat::test_that("extract_dataset_name_from_sample_names() errors on NULL input", {
  testthat::expect_error(
    extract_dataset_name_from_sample_names(NULL),
    regexp = "character"
  )
})

testthat::test_that("extract_dataset_name_from_sample_names() errors on numeric input", {
  testthat::expect_error(
    extract_dataset_name_from_sample_names(123),
    regexp = "character"
  )
})

testthat::test_that("extract_dataset_name_from_sample_names() errors on empty vector", {
  testthat::expect_error(
    extract_dataset_name_from_sample_names(base::character()),
    regexp = "empty"
  )
})

testthat::test_that("extract_dataset_name_from_sample_names() errors when __ is missing", {
  testthat::expect_error(
    extract_dataset_name_from_sample_names(c("dataset1__500", "no_separator")),
    regexp = "__"
  )
})

testthat::test_that(
  "extract_dataset_name_from_sample_names() errors on single missing __",
  {
    testthat::expect_error(
      extract_dataset_name_from_sample_names(c("noseparator")),
      regexp = "__"
    )
  }
)

# Output Structure

testthat::test_that("extract_dataset_name_from_sample_names() returns character type", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    extract_dataset_name_from_sample_names(vec_names)

  testthat::expect_type(result, "character")
})

testthat::test_that(
  "extract_dataset_name_from_sample_names() output length equals input length",
  {
    vec_names <-
      c("dataset1__500", "dataset2__750", "dataset3__1000")

    result <-
      extract_dataset_name_from_sample_names(vec_names)

    testthat::expect_length(result, base::length(vec_names))
  }
)

# Functional Correctness

testthat::test_that("extract_dataset_name_from_sample_names() returns correct values", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    extract_dataset_name_from_sample_names(vec_names)

  expected_result <-
    c("dataset1", "dataset2", "dataset3")

  testthat::expect_equal(result, expected_result)
})

testthat::test_that(
  "extract_dataset_name_from_sample_names() handles single-element input",
  {
    vec_single <-
      c("mysite__750")

    result <-
      extract_dataset_name_from_sample_names(vec_single)

    testthat::expect_equal(result, "mysite")
  }
)

testthat::test_that(
  "extract_dataset_name_from_sample_names() handles names with underscores",
  {
    vec_names <-
      c("my_site__100", "another_dataset__200")

    result <-
      extract_dataset_name_from_sample_names(vec_names)

    testthat::expect_equal(result, c("my_site", "another_dataset"))
  }
)

testthat::test_that(
  "extract_dataset_name_from_sample_names() extracts everything before last __",
  {
    vec_names <-
      c("site__a__b", "dataset__1000__old")

    result <-
      extract_dataset_name_from_sample_names(vec_names)

    testthat::expect_equal(result, c("site__a", "dataset__1000"))
  }
)

testthat::test_that("extract_dataset_name_from_sample_names() trims whitespace", {
  vec_names <-
    c("  my_site  __100")

  result <-
    extract_dataset_name_from_sample_names(vec_names)

  testthat::expect_equal(result, "my_site")
})

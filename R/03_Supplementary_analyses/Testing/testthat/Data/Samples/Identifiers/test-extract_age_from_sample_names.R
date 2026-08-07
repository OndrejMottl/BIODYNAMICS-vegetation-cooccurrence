# Input Validation

testthat::test_that("extract_age_from_sample_names() errors on NULL input", {
  testthat::expect_error(
    extract_age_from_sample_names(NULL),
    regexp = "character"
  )
})

testthat::test_that("extract_age_from_sample_names() errors on numeric input", {
  testthat::expect_error(
    extract_age_from_sample_names(123),
    regexp = "character"
  )
})

testthat::test_that("extract_age_from_sample_names() errors on empty vector", {
  testthat::expect_error(
    extract_age_from_sample_names(base::character()),
    regexp = "empty"
  )
})

testthat::test_that("extract_age_from_sample_names() errors when __ is missing", {
  testthat::expect_error(
    extract_age_from_sample_names(c("dataset1__500", "no_separator")),
    regexp = "__"
  )
})

testthat::test_that("extract_age_from_sample_names() errors on single missing __", {
  testthat::expect_error(
    extract_age_from_sample_names(c("noseparator")),
    regexp = "__"
  )
})

# Output Structure

testthat::test_that("extract_age_from_sample_names() returns character type", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    extract_age_from_sample_names(vec_names)

  testthat::expect_type(result, "character")
})

testthat::test_that("extract_age_from_sample_names() output length equals input length", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    extract_age_from_sample_names(vec_names)

  testthat::expect_length(result, base::length(vec_names))
})

# Functional Correctness

testthat::test_that("extract_age_from_sample_names() returns correct values", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    extract_age_from_sample_names(vec_names)

  expected_result <-
    c("500", "750", "1000")

  testthat::expect_equal(result, expected_result)
})

testthat::test_that("extract_age_from_sample_names() handles single-element input", {
  vec_single <-
    c("site1__500")

  result <-
    extract_age_from_sample_names(vec_single)

  testthat::expect_equal(result, "500")
})

testthat::test_that(
  "extract_age_from_sample_names() handles dataset names with underscores",
  {
    vec_names <-
      c("my_site__100", "another_dataset__200")

    result <-
      extract_age_from_sample_names(vec_names)

    testthat::expect_equal(result, c("100", "200"))
  }
)

testthat::test_that("extract_age_from_sample_names() handles decimal ages", {
  vec_names <-
    c("site1__100.5", "site2__200.75")

  result <-
    extract_age_from_sample_names(vec_names)

  testthat::expect_equal(result, c("100.5", "200.75"))
})

testthat::test_that(
  "extract_age_from_sample_names() extracts everything after first __",
  {
    vec_names <-
      c("site__a__b", "dataset__1000__old")

    result <-
      extract_age_from_sample_names(vec_names)

    testthat::expect_equal(result, c("a__b", "1000__old"))
  }
)

testthat::test_that("extract_age_from_sample_names() trims whitespace from result", {
  vec_names <-
    c("site1__  100  ")

  result <-
    extract_age_from_sample_names(vec_names)

  testthat::expect_equal(result, "100")
})

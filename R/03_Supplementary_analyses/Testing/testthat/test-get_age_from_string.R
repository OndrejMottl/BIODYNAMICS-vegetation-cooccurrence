# Input Validation

testthat::test_that("get_age_from_string() errors on NULL input", {
  testthat::expect_error(
    get_age_from_string(NULL),
    regexp = "character"
  )
})

testthat::test_that("get_age_from_string() errors on numeric input", {
  testthat::expect_error(
    get_age_from_string(123),
    regexp = "character"
  )
})

testthat::test_that("get_age_from_string() errors on empty vector", {
  testthat::expect_error(
    get_age_from_string(base::character()),
    regexp = "empty"
  )
})

testthat::test_that("get_age_from_string() errors when __ is missing", {
  testthat::expect_error(
    get_age_from_string(c("dataset1__500", "no_separator")),
    regexp = "__"
  )
})

testthat::test_that("get_age_from_string() errors on single missing __", {
  testthat::expect_error(
    get_age_from_string(c("noseparator")),
    regexp = "__"
  )
})

# Output Structure

testthat::test_that("get_age_from_string() returns character type", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_age_from_string(vec_names)

  testthat::expect_type(result, "character")
})

testthat::test_that("get_age_from_string() output length equals input length", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_age_from_string(vec_names)

  testthat::expect_length(result, base::length(vec_names))
})

# Functional Correctness

testthat::test_that("get_age_from_string() returns correct values", {
  vec_names <-
    c("dataset1__500", "dataset2__750", "dataset3__1000")

  result <-
    get_age_from_string(vec_names)

  expected_result <-
    c("500", "750", "1000")

  testthat::expect_equal(result, expected_result)
})

testthat::test_that("get_age_from_string() handles single-element input", {
  vec_single <-
    c("site1__500")

  result <-
    get_age_from_string(vec_single)

  testthat::expect_equal(result, "500")
})

testthat::test_that(
  "get_age_from_string() handles dataset names with underscores",
  {
    vec_names <-
      c("my_site__100", "another_dataset__200")

    result <-
      get_age_from_string(vec_names)

    testthat::expect_equal(result, c("100", "200"))
  }
)

testthat::test_that("get_age_from_string() handles decimal ages", {
  vec_names <-
    c("site1__100.5", "site2__200.75")

  result <-
    get_age_from_string(vec_names)

  testthat::expect_equal(result, c("100.5", "200.75"))
})

testthat::test_that(
  "get_age_from_string() extracts everything after first __",
  {
    vec_names <-
      c("site__a__b", "dataset__1000__old")

    result <-
      get_age_from_string(vec_names)

    testthat::expect_equal(result, c("a__b", "1000__old"))
  }
)

testthat::test_that("get_age_from_string() trims whitespace from result", {
  vec_names <-
    c("site1__  100  ")

  result <-
    get_age_from_string(vec_names)

  testthat::expect_equal(result, "100")
})

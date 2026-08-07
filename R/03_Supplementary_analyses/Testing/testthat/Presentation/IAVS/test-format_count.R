testthat::test_that(
  "format_count() formats grouped count labels",
  {
    res <-
      format_count(
        x = c(1200, 5000000)
      )

    testthat::expect_identical(
      res,
      c("1,200", "5,000,000")
    )
  }
)

testthat::test_that(
  "format_count() validates arguments",
  {
    testthat::expect_error(
      format_count(
        x = "abc"
      ),
      regexp = "x"
    )

    testthat::expect_error(
      format_count(
        x = 1,
        accuracy = 0
      ),
      regexp = "accuracy"
    )
  }
)

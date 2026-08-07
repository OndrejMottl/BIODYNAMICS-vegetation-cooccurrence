testthat::test_that(
  "format_age_label() formats years to ka BP",
  {
    res <-
      format_age_label(
        age = 2500
      )

    testthat::expect_identical(res, "2.5 ka BP")
  }
)

testthat::test_that(
  "format_age_label() validates scalar age",
  {
    testthat::expect_error(
      format_age_label(
        age = c(1000, 2000)
      ),
      regexp = "age"
    )
  }
)

testthat::test_that(
  ".muffle_package_version_warning() muffles matching warnings",
  {
    testthat::expect_silent(
      base::withCallingHandlers(
        base::warning(
          "package 'example' was built under R version 4.5.2",
          call. = FALSE
        ),
        warning = .muffle_package_version_warning
      )
    )
  }
)

testthat::test_that(
  ".muffle_package_version_warning() preserves unrelated warnings",
  {
    testthat::expect_warning(
      base::withCallingHandlers(
        base::warning(
          "ordinary warning",
          call. = FALSE
        ),
        warning = .muffle_package_version_warning
      ),
      regexp = "ordinary warning"
    )
  }
)

testthat::test_that(
  ".muffle_package_version_warning() returns invisibly otherwise",
  {
    warning_condition <-
      base::simpleWarning("ordinary warning")

    res_handler <-
      .muffle_package_version_warning(warning_condition)

    testthat::expect_null(res_handler)
  }
)

testthat::test_that(
  "build_manuscript_theme() returns a complete neutral theme",
  {
    res_theme <-
      build_manuscript_theme()

    testthat::expect_s3_class(res_theme, "theme")
    testthat::expect_true(
      base::isTRUE(base::attr(res_theme, "complete"))
    )
    testthat::expect_identical(
      res_theme[["plot.background"]][["fill"]],
      "white"
    )
    testthat::expect_identical(
      res_theme[["text"]][["family"]],
      "sans"
    )
  }
)

testthat::test_that(
  "build_manuscript_theme() validates typography arguments",
  {
    testthat::expect_error(
      build_manuscript_theme(base_size = 0),
      "positive"
    )
    testthat::expect_error(
      build_manuscript_theme(base_family = ""),
      "non-empty"
    )
  }
)

testthat::test_that(
  "resolve_manuscript_graphical_options() preserves physical figure size",
  {
    config_resolved <-
      resolve_manuscript_graphical_options(
        base::list(
          width = 1800,
          height = 1200,
          units = "px",
          dpi = 300,
          bg = "white"
        )
      )

    testthat::expect_equal(config_resolved[["width"]], 6)
    testthat::expect_equal(config_resolved[["height"]], 4)
    testthat::expect_identical(config_resolved[["units"]], "in")
    testthat::expect_equal(config_resolved[["review_dpi"]], 300)
    testthat::expect_equal(config_resolved[["submission_dpi"]], 600)
  }
)

testthat::test_that(
  "resolve_manuscript_graphical_options() retains configured physical units",
  {
    config_resolved <-
      resolve_manuscript_graphical_options(
        base::list(
          width = 183,
          height = 145,
          units = "mm",
          dpi = 300,
          bg = "white"
        )
      )

    testthat::expect_equal(config_resolved[["width"]], 183)
    testthat::expect_equal(config_resolved[["height"]], 145)
    testthat::expect_identical(config_resolved[["units"]], "mm")
  }
)

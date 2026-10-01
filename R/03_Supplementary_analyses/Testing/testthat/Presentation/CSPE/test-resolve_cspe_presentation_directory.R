testthat::test_that(
  "resolve_cspe_presentation_directory() honors its override",
  {
    path_override <-
      base::tempdir()

    withr::local_envvar(
      .new = base::c(CSPE_PRESENTATION_DIR = path_override)
    )

    path_resolved <-
      resolve_cspe_presentation_directory()

    testthat::expect_identical(
      path_resolved,
      base::normalizePath(
        path_override,
        winslash = "/",
        mustWork = FALSE
      )
    )
  }
)

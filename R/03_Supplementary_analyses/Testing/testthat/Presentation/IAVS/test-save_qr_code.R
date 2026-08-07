testthat::test_that(
  "save_qr_code() writes SVG and returns path",
  {
    path_temp <-
      base::file.path(
        tempdir(),
        "qr_test"
      )

    res <-
      save_qr_code(
        url = "https://example.com",
        name = "example",
        background_color = "#000000",
        foreground_color = "#ffffff",
        plot = FALSE,
        base_path = path_temp
      )

    testthat::expect_true(base::file.exists(res))
    testthat::expect_match(res, "qr_example[.]svg$")
  }
)

testthat::test_that(
  "save_qr_code() validates URL",
  {
    testthat::expect_error(
      save_qr_code(
        url = "",
        name = "x",
        background_color = "#000000",
        foreground_color = "#ffffff",
        plot = FALSE,
        base_path = tempdir()
      ),
      regexp = "url"
    )
  }
)

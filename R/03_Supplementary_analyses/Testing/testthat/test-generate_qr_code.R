testthat::test_that(
  "generate_qr_code() writes SVG and returns path",
  {
    path_temp <-
      base::file.path(
        tempdir(),
        "qr_test"
      )

    res <-
      generate_qr_code(
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
  "generate_qr_code() validates URL",
  {
    testthat::expect_error(
      generate_qr_code(
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

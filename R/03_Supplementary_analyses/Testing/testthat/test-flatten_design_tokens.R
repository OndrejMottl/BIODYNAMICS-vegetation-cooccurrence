testthat::test_that("flatten_design_tokens() includes custom sections", {
  list_design <-
    base::list(
      config =
        base::list(
          metadata = base::list(name = "ORACLE"),
          palette = base::list(text = "#B8F77A"),
          frame = base::list(radius = "0.18rem"),
          sizing = base::list(story_image_max_height = "580px")
        )
    )

  list_tokens <-
    flatten_design_tokens(design = list_design)

  testthat::expect_equal(
    list_tokens[["oracle-frame-radius"]],
    "0.18rem"
  )
  testthat::expect_equal(
    list_tokens[["oracle-sizing-story-image-max-height"]],
    "580px"
  )
  testthat::expect_false(
    "oracle-metadata-name" %in% base::names(list_tokens)
  )
})

testthat::test_that("generated SCSS includes Reveal theme defaults", {
  list_design <-
    base::list(
      config =
        base::list(
          palette = base::list(background = "#010301"),
          typography = base::list(body_family = "monospace")
        ),
      config_dir = base::tempdir()
    )

  vec_output_path <-
    write_oracle_generated_scss(
      design = list_design,
      output = "test_oracle_generated.scss"
    )
  vec_output <-
    base::readLines(con = vec_output_path)

  testthat::expect_true(
    base::any(
      base::grepl(
        pattern = "\\$backgroundColor: \\$oracle-palette-background",
        x = vec_output
      )
    )
  )
  testthat::expect_true(
    base::any(
      base::grepl(
        pattern = "\\$mainFont: \\$oracle-typography-body-family",
        x = vec_output
      )
    )
  )

  base::unlink(x = vec_output_path)
})

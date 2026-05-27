#' @title Write auto-generated SCSS from design tokens
#' @description Converts the design configuration returned by
#'   `load_design_config()` into SCSS variables and CSS custom
#'   properties, then writes them to a SCSS file.
#' @param design Named list as returned by `load_design_config()`.
#' @param output Character scalar. Output file name or absolute path.
#'   When relative, written next to the JSON config file.
#' @return Invisibly, the absolute path to the written file.
#' @examples
#' \dontrun{
#' design <- load_design_config()
#' write_oracle_generated_scss(design)
#' }
write_oracle_generated_scss <- function(
    design,
    output = "oracle_generated.scss") {
  assertthat::assert_that(
    base::is.list(design),
    msg = "'design' must be a list as returned by load_design_config()."
  )
  assertthat::assert_that(
    base::is.character(output),
    base::length(output) == 1L,
    msg = "'output' must be a character scalar."
  )

  if (
    !base::exists("flatten_design_tokens", mode = "function")
  ) {
    base::source(
      here::here(
        "R",
        "Functions",
        "Presentation",
        "IAVS",
        "flatten_design_tokens.R"
      )
    )
  }
  if (
    !base::exists("format_scss_value", mode = "function")
  ) {
    base::source(
      here::here(
        "R",
        "Functions",
        "Presentation",
        "IAVS",
        "format_scss_value.R"
      )
    )
  }

  list_tokens <-
    flatten_design_tokens(design)
  vec_config_dir <-
    purrr::chuck(design, "config_dir")

  if (
    !base::nzchar(vec_config_dir)
  ) {
    if (
      !base::exists("get_presentation_dir", mode = "function")
    ) {
      base::source(
        here::here(
          "R",
          "Functions",
          "Presentation",
          "IAVS",
          "get_presentation_dir.R"
        )
      )
    }
    vec_config_dir <-
      get_presentation_dir()
  }

  vec_output_path <- output
  if (
    !stringr::str_detect(output, "^([A-Za-z]:)?[/\\\\]")
  ) {
    vec_output_path <-
      base::file.path(vec_config_dir, output)
  }

  vec_token_names <-
    base::names(list_tokens)
  vec_token_values <-
    purrr::map_chr(
      .x = list_tokens,
      .f = ~ format_scss_value(.x)
    )

  vec_scss_variables <-
    stringr::str_c(
      "$",
      vec_token_names,
      ": ",
      vec_token_values,
      " !default;"
    )

  vec_css_variables <-
    stringr::str_c(
      "  --",
      vec_token_names,
      ": ",
      vec_token_values,
      ";"
    )

  # Reveal theme defaults must be present in the imported generated file.
  # Referencing imported oracle variables from oracle.scss is evaluated too
  # early by Quarto's theme compiler and produces false undeclared warnings.
  vec_reveal_defaults <-
    base::c(
      "$backgroundColor: $oracle-palette-background !default;",
      "$mainColor: $oracle-palette-text !default;",
      "$headingColor: $oracle-palette-phosphor !default;",
      "$linkColor: $oracle-palette-cyan !default;",
      "$selectionBackgroundColor: $oracle-palette-border !default;",
      "$mainFont: $oracle-typography-body-family !default;",
      "$headingFont: $oracle-typography-heading-family !default;",
      "$mainFontSize: $oracle-typography-body-size !default;",
      "$headingFontWeight: $oracle-typography-heading-weight !default;",
      "$headingTextTransform: $oracle-typography-heading-transform !default;",
      base::paste0(
        "$headingLetterSpacing: ",
        "$oracle-typography-heading-letter-spacing !default;"
      )
    )

  vec_lines <-
    base::c(
      "// Auto-generated from design_config.json. Do not edit.",
      "",
      vec_scss_variables,
      "",
      "// Reveal.js compile-time defaults derived from the same design tokens.",
      vec_reveal_defaults,
      "",
      ":root,",
      ".reveal {",
      vec_css_variables,
      "}"
    )

  base::writeLines(vec_lines, con = vec_output_path, useBytes = TRUE)

  return(
    base::invisible(
      base::normalizePath(
        vec_output_path,
        winslash = "/",
        mustWork = FALSE
      )
    )
  )
}

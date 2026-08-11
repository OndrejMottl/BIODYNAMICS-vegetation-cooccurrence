#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                    Render website
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Render the project website (root _quarto.yml) to docs/.
#
# The root _quarto.yml already sets output-dir: docs, so no copy step
# is needed. The IAVS presentation is rendered separately into docs/,
# so the website render uses --no-clean to preserve those artifacts.
#
# Run via:
#   Rscript R/03_Supplementary_analyses/Documentation/Render_website.R

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(quarto)

quarto::quarto_render(
  input = here::here("."),
  quarto_args = "--no-clean"
)

vec_generated_text_files <-
  base::c(
    here::here("docs/index.html"),
    fs::dir_ls(
      path = here::here("docs/Documentation/Website"),
      recurse = TRUE,
      type = "file",
      regexp = "[.]html$"
    )
  )

purrr::walk(
  .x = vec_generated_text_files,
  .f = ~ {
    vec_lines <-
      base::readLines(
        con = .x,
        warn = FALSE,
        encoding = "UTF-8"
      ) |>
      stringr::str_replace("[[:blank:]]+$", "")

    while (
      base::length(vec_lines) > 0L &&
        vec_lines[[base::length(vec_lines)]] == ""
    ) {
      vec_lines <- vec_lines[-base::length(vec_lines)]
    }

    readr::write_lines(
      x = vec_lines,
      file = .x,
      sep = "\n"
    )

    return(invisible(NULL))
  }
)

cli::cli_inform(
  c("v" = "Website rendered to {here::here('docs')}.")
)

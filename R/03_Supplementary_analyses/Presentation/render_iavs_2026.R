#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#          Render IAVS 2026 presentation
#
#                   O. Mottl
#                    2026
#
#----------------------------------------------------------#
# Render the IAVS 2026 RevealJS presentation.
#   This script renders only the presentation artifacts published in
#   docs/. The full website shell is rendered separately by
#   R/03_Supplementary_analyses/Documentation/Render_website.R.

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_presentation <-
  here::here("Documentation/Presentations/IAVS_2026")

path_presentation_source <-
  base::file.path(path_presentation, "index.qmd")

path_presentation_output <-
  here::here("docs/Documentation/Presentations/IAVS_2026")

path_presentation_html <-
  base::file.path(path_presentation_output, "index.html")

path_presentation_pdf <-
  base::file.path(
    path_presentation_output,
    "iavs_2026_presentation.pdf"
  )

path_presentation_pdf_html <-
  base::paste0(
    "file:///",
    base::chartr(
      old = "\\",
      new = "/",
      x = path_presentation_html
    ),
    "?pdf-static=true"
  )


#----------------------------------------------------------#
# 1. Pre-render design tokens -----
#----------------------------------------------------------#

source(
  base::file.path(path_presentation, "R/pre_render.R")
)


#----------------------------------------------------------#
# 2. Render HTML deck -----
#----------------------------------------------------------#

base::dir.create(
  path = path_presentation_output,
  showWarnings = FALSE,
  recursive = TRUE
)

quarto::quarto_render(
  input = path_presentation_source,
  quarto_args = c(
    "--output-dir",
    path_presentation_output
  )
)

if (
  !base::file.exists(path_presentation_html)
) {
  base::stop(
    "The presentation render completed without the expected HTML output."
  )
}

cli::cli_inform(
  "Presentation HTML rendered to {path_presentation_html}."
)


#----------------------------------------------------------#
# 3. Render PDF deck -----
#----------------------------------------------------------#

vec_decktape_arguments <-
  c(
    "reveal",
    "--size",
    "1600x900",
    path_presentation_pdf_html,
    path_presentation_pdf
  )

vec_decktape_status <-
  base::system2(
    command = "decktape.cmd",
    args = vec_decktape_arguments
  )

if (
  !base::identical(vec_decktape_status, 0L)
) {
  base::stop("PDF rendering failed while running decktape.")
}

if (
  !base::file.exists(path_presentation_pdf)
) {
  base::stop(
    "The PDF render completed without the expected PDF output."
  )
}

cli::cli_inform(
  "Presentation PDF rendered to {path_presentation_pdf}."
)

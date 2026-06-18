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

cli::cli_inform(
  c("v" = "Website rendered to {here::here('docs')}.")
)

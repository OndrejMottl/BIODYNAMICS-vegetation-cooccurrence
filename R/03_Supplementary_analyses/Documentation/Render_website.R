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
# is needed. Any stale files in docs/ that no longer correspond to a
# source .qmd will remain until quarto itself removes them.
#
# Run via:
#   Rscript R/03_Supplementary_analyses/Documentation/Render_website.R

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(quarto)

quarto::quarto_render(
  input = here::here(".")
)

cli::cli_inform(
  c("v" = "Website rendered to {here::here('docs')}.")
)

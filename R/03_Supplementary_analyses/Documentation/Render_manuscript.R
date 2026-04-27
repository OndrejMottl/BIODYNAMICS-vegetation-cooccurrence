#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                  Render manuscript
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Render the Quarto manuscript project to Documentation/Manuscript/_output/
# and copy the rendered output into docs/Manuscript/ for GitHub Pages.
#
# Documentation/Manuscript/_quarto.yml sets output-dir: _output, so
# quarto renders into Documentation/Manuscript/_output/. The fs::dir_copy()
# call below then mirrors that into docs/Manuscript/ so the rendered
# manuscript is accessible on the project website.
#
# Run via:
#   Rscript R/03_Supplementary_analyses/Documentation/Render_manuscript.R

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(quarto)
library(fs)

path_manuscript <-
  here::here("Documentation/Manuscript")

path_output <-
  fs::path(path_manuscript, "_output")

path_docs_target <-
  here::here("docs/Manuscript")

#----------------------------------------------------------#
# 1. Render -----
#----------------------------------------------------------#

quarto::quarto_render(
  input = path_manuscript
)

cli::cli_inform(
  c("v" = "Manuscript rendered to {path_output}.")  
)

#----------------------------------------------------------#
# 2. Copy rendered output into docs/ -----
#----------------------------------------------------------#

fs::dir_copy(
  path = path_output,
  new_path = path_docs_target,
  overwrite = TRUE
)

cli::cli_inform(
  c("v" = "Manuscript copied to {path_docs_target}.")
)

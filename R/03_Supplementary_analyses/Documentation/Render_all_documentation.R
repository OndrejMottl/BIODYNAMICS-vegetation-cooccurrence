#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#               Render all documentation
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Master script that regenerates every documentation artefact in order:
#
#   1. Document_functions.R    — Rebuild roxygen2 HTML + function .qmd pages
#   2. Estimate_test_coverage.R — Recompute coverage report and JSON summary
#   3. Render_website.R        — Render the project website to docs/
#   4. Render_manuscript.R     — Render the manuscript and
#      copy to docs/Manuscript/
#
# Steps 1 and 2 must precede the website render so that function pages
# and the coverage badge reflect the current state of the codebase.
#
# Run via:
#   Rscript R/03_Supplementary_analyses/Documentation/Render_all_documentation.R

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_documentation <-
  here::here("R/03_Supplementary_analyses/Documentation")

path_testing <-
  here::here("R/03_Supplementary_analyses/Testing")

#----------------------------------------------------------#
# 1. Regenerate function documentation pages -----
#----------------------------------------------------------#

cli::cli_h1("Step 1/4: Documenting functions")

source(
  stringr::str_glue("{path_documentation}/Document_functions.R")
)

#----------------------------------------------------------#
# 2. Recompute test coverage -----
#----------------------------------------------------------#

cli::cli_h1("Step 2/4: Estimating test coverage")

source(
  stringr::str_glue("{path_testing}/Estimate_test_coverage.R")
)

#----------------------------------------------------------#
# 3. Render website -----
#----------------------------------------------------------#

cli::cli_h1("Step 3/4: Rendering website")

source(
  stringr::str_glue("{path_documentation}/Render_website.R")
)

#----------------------------------------------------------#
# 4. Render manuscript -----
#----------------------------------------------------------#

cli::cli_h1("Step 4/4: Rendering manuscript")

source(
  stringr::str_glue("{path_documentation}/Render_manuscript.R")
)

cli::cli_inform(
  c("v" = "All documentation artefacts rebuilt successfully.")
)

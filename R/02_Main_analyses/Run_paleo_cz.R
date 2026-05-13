#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Run pipelines: paleo CZ
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for the paleo CZ validation pipelines.
# Intended as a quick sanity check that the core and
#   resolution-test pipelines are working correctly.
# R_SPATIAL_ID is intentionally not set; spatial bounds
#   are read directly from config.yml (project_paleo_core_cz block).


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

base::suppressWarnings(
  source(
    here::here("R/___setup_project___.R")
  )
)


#----------------------------------------------------------#
# 1. Set active configuration -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_core_cz")


#----------------------------------------------------------#
# 2. Run pipelines -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_paleo_core.R",
  fresh_run = TRUE
)

run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_paleo_resolution_test.R",
  fresh_run = TRUE
)

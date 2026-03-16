#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Run pipeline: project_cz
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for project_cz.
# Intended as a quick sanity check that the full pipeline
#   and all functions are working correctly.
# R_SPATIAL_ID is intentionally not set; spatial bounds
#   are read directly from config.yml (project_cz block).


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Set active configuration -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_cz")


#----------------------------------------------------------#
# 2. Run pipelines -----
#----------------------------------------------------------#

# Basic pipeline
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)

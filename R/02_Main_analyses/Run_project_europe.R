#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Run pipeline: project_europe
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for project_europe.
# R_SPATIAL_ID is intentionally not set; spatial bounds
#   are read directly from config.yml (project_europe block).


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

Sys.setenv(R_CONFIG_ACTIVE = "project_europe")


#----------------------------------------------------------#
# 2. Run pipelines -----
#----------------------------------------------------------#

# Basic pipeline
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)

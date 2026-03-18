#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Run temporal pipeline: Europe (project_temporal_europe)
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the time-slice pipeline for the pan-European region.
# Uses project_temporal_europe configuration (lon -10–40°E, lat 35–70°N,
#   0–20 kyr BP, 500-yr steps).
# Target store: Data/targets/project_temporal_europe/pipeline_time/


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

Sys.setenv(R_CONFIG_ACTIVE = "project_temporal_europe")


#----------------------------------------------------------#
# 2. Run pipeline -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_time.R",
  level_separation = 100
)

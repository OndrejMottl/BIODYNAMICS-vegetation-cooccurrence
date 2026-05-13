#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Run temporal pipeline: Americas (project_paleo_temporal_america)
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the time-slice pipeline for the North American region.
# Uses project_paleo_temporal_america configuration (lon -130–-60°W, lat 30–70°N,
#   0–20 kyr BP, 500-yr steps).
# Target store: Data/targets/paleo_temporal_america/pipeline_paleo_temporal/


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

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_america")


#----------------------------------------------------------#
# 2. Run pipeline -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_temporal.R",
  level_separation = 100
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        Monitor paleo spatial pipeline progress
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Lightweight example launcher for the official {targets} dashboard.

library(here)

base::source(
  here::here(
    "R/Functions/Utility/Pipeline/monitor_pipeline_progress.R"
  )
)

monitor_pipeline_progress(
  sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
  sel_config = "project_paleo_spatial_continental",
  store_suffix = "europe"
)

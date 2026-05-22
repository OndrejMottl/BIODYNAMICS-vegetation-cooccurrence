#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Run CZ validation/test pipelines
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for Czechia-scale validation pipelines.
# Runs the small paleo CZ gates and the modern spatial test used
#   to validate shared spatial preprocessing. The modern test
#   builds its own CZ FT classification, so it does not require
#   a pre-existing Europe-wide modern FT file.


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
# 1. Paleo CZ pipelines -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_core.R",
  fresh_run = TRUE
)

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_resolution_test.R",
  fresh_run = TRUE
)


#----------------------------------------------------------#
# 2. Modern CZ spatial quick test -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_modern")

scale_id <- "eu_r005_l014"

run_pipeline(
  sel_script = "R/Pipelines/pipeline_modern_spatial_resolution_test.R",
  store_suffix = scale_id,
  fresh_run = TRUE
)

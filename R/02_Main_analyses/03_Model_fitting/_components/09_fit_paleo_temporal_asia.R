#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Fit paleo temporal Asia models
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the time-slice pipeline for the Asian region.
# Uses project_paleo_temporal_asia configuration (lon 60–140°E, lat 50–75°N,
#   0–20 kyr BP, 500-yr steps).
# Target store: Data/targets/paleo_temporal_asia/pipeline_paleo_temporal/
# Workflow contract:
#   Requires completed preparation from stage 01 and calibrated CV budgets
#   from stage 02. It runs tuning and final fitting only and reuses cached
#   preparation. Rerun stage 03 after interruption to resume completed work.

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

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_asia")


#----------------------------------------------------------#
# 2. Load time-slice targets -----
#----------------------------------------------------------#

vec_age_lim <-
  load_active_config_value(base::c("vegvault_data", "age_lim"))

vec_tuning_target_names <-
  stringr::str_c(
    "list_sjsdm_cv_tuning_artifact_timeslice_",
    base::seq(
      from = base::min(vec_age_lim),
      to = base::max(vec_age_lim),
      by = load_active_config_value(base::c("data_processing", "time_step"))
    )
  )

#----------------------------------------------------------#
# 3. Build tuning summaries and shared tier artifact -----
#----------------------------------------------------------#

run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_temporal.R",
  tuning_target_names = vec_tuning_target_names,
  prebuild_interpolation = TRUE,
  tuning_strategy = load_active_config_value(
    base::c("model_fitting", "cross_validation", "tuning_strategy")
  ),
  n_rounds = base::length(
    load_active_config_value(
      base::c(
        "model_fitting",
        "cross_validation",
        "staged_search",
        "repeat_order"
      )
    )
  )
)


#----------------------------------------------------------#
# 4. Complete temporal pipeline -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_temporal.R",
  level_separation = 100,
  prebuild_interpolation = FALSE
)

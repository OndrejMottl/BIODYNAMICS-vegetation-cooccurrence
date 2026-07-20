#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Run temporal pipeline: Asia (project_paleo_temporal_asia)
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the time-slice pipeline for the Asian region.
# Uses project_paleo_temporal_asia configuration (lon 60–140°E, lat 50–75°N,
#   0–20 kyr BP, 500-yr steps).
# Target store: Data/targets/paleo_temporal_asia/pipeline_paleo_temporal/


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
# 2. Build tuning summaries and shared tier artifact -----
#----------------------------------------------------------#

vec_age_lim <-
  get_active_config(base::c("vegvault_data", "age_lim"))

vec_tuning_target_names <-
  stringr::str_c(
    "data_sjsdm_tuning_summary_timeslice_",
    base::seq(
      from = base::min(vec_age_lim),
      to = base::max(vec_age_lim),
      by = get_active_config(base::c("data_processing", "time_step"))
    )
  )

run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_temporal.R",
  tuning_target_names = vec_tuning_target_names,
  prebuild_interpolation = TRUE,
  tuning_strategy = get_active_config(
    base::c("model_fitting", "cross_validation", "tuning_strategy")
  ),
  n_rounds = base::length(
    get_active_config(
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
# 3. Complete temporal pipeline -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_temporal.R",
  level_separation = 100,
  prebuild_interpolation = TRUE
)

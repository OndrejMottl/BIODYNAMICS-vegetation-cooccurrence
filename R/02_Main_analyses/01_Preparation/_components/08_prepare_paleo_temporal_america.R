#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Prepare paleo temporal America folds
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Caches every configured American time-slice fold without tuning or model
#   fitting. Missing current time-slice evidence blocks calibration.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))
Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_america")

vec_runner_arguments <-
  base::commandArgs(trailingOnly = TRUE)
preparation_resource_profile <-
  if (
    base::length(vec_runner_arguments) >= 1L
  ) {
    vec_runner_arguments[[1L]]
  } else {
    "shared"
  }
interpolation_workers_override <-
  if (
    base::length(vec_runner_arguments) >= 2L
  ) {
    base::as.numeric(vec_runner_arguments[[2L]])
  } else {
    NULL
  }


#----------------------------------------------------------#
# 1. Prepare time slices -----
#----------------------------------------------------------#

vec_age_lim <-
  load_active_config_value(base::c("vegvault_data", "age_lim"))
vec_target_names <-
  stringr::str_c(
    "list_sjsdm_prepared_tuning_folds_timeslice_",
    base::seq(
      from = base::min(vec_age_lim),
      to = base::max(vec_age_lim),
      by = load_active_config_value(
        base::c("data_processing", "time_step")
      )
    )
  )

run_sjsdm_cv_preparation_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_temporal.R",
  preparation_target_names = vec_target_names,
  prebuild_interpolation = TRUE,
  preparation_resource_profile = preparation_resource_profile,
  interpolation_workers_override = interpolation_workers_override
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Prepare paleo temporal Europe folds
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Caches every configured European time-slice fold without tuning or model
#   fitting. Missing current time-slice evidence blocks calibration.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))
Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_europe")

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

# Modelled slices only (temporal_slices.age_window; issue #181).
vec_target_names <-
  stringr::str_c(
    "list_sjsdm_prepared_tuning_folds_timeslice_",
    load_temporal_slice_ages() |>
      dplyr::pull("age")
  )

run_sjsdm_cv_preparation_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_temporal.R",
  preparation_target_names = vec_target_names,
  prebuild_interpolation = TRUE,
  preparation_resource_profile = preparation_resource_profile,
  interpolation_workers_override = interpolation_workers_override
)

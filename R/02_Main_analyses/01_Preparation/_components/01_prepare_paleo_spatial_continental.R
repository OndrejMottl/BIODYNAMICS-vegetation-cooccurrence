#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Prepare paleo spatial continental folds
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   First preparation component. It publishes current paleo functional-type
#   classifications and caches prepared CV folds without fitting any model.
#   Expected infeasible units are recorded; unexplained failures are fatal.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))
Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_continental")

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
# 1. Prepare continental units -----
#----------------------------------------------------------#

vec_scale_ids <-
  load_continental_spatial_grid_rows(
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv")
  ) |>
  dplyr::pull(scale_id)

run_sjsdm_cv_preparation_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
  preparation_target_names = stringr::str_c(
    "list_sjsdm_prepared_tuning_folds_",
    base::c("genus", "family", "functional_type")
  ),
  unit_store_suffixes = vec_scale_ids,
  prebuild_interpolation = TRUE,
  preparation_resource_profile = preparation_resource_profile,
  interpolation_workers_override = interpolation_workers_override
)

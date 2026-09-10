#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               Prepare modern spatial local folds
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Requires current modern continental functional-type classifications.
#   Caches local prepared CV folds without tuning or model fitting.
#   Expected infeasible units are recorded; unexplained failures are fatal.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))
Sys.setenv(R_CONFIG_ACTIVE = "project_modern_spatial_local")

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
# 1. Prepare local units -----
#----------------------------------------------------------#

vec_scale_ids <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["scale"]] == "local") |>
  dplyr::pull(scale_id)

run_sjsdm_cv_preparation_sequence(
  unit_pipeline = "R/Pipelines/pipeline_modern_spatial_resolution.R",
  preparation_target_names = stringr::str_c(
    "list_sjsdm_prepared_tuning_folds_",
    base::c("genus", "family", "ft_modern")
  ),
  unit_store_suffixes = vec_scale_ids,
  prebuild_interpolation = FALSE,
  preparation_resource_profile = preparation_resource_profile,
  interpolation_workers_override = interpolation_workers_override
)

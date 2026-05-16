#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        {targets} pipe: Sample-level spatial predictors
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Builds sample-level spatial predictors for a specific model
#   branch from shared spatial targets and branch sample IDs.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_model_spatial_samples <-
  list(
    targets::tar_target(
      description = stringr::str_c(
        "Build sample-level spatial MEV predictors from shared ",
        "2-D MEVs or branch-specific 3-D MEVs"
      ),
      name = "data_spatial_mev_samples",
      command = {
        if (
          isFALSE(config_spatial_predictors$use_spatial)
        ) {
          NULL
        } else if (
          config_spatial_predictors$spatial_mode == "spatial"
        ) {
          prepare_spatial_predictors_for_fit(
            data_spatial = data_spatial_mev_core,
            data_sample_ids = data_sample_ids_checked
          )
        } else {
          compute_spatiotemporal_mev(
            data_coords_projected = data_coords_projected,
            data_sample_ids = data_sample_ids_checked,
            n_mev = config_spatial_predictors$n_mev
          )
        }
      }
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Scale spatial MEV predictors; capture attributes for ",
        "back-transformation"
      ),
      name = "data_spatial_scaled_list",
      command = {
        if (
          isFALSE(config_spatial_predictors$use_spatial) ||
            is.null(data_spatial_mev_samples)
        ) {
          NULL
        } else {
          scale_spatial_for_fit(
            data_spatial = data_spatial_mev_samples
          )
        }
      }
    )
  )

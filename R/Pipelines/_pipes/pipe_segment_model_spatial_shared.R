#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Shared spatial predictors
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines spatial predictor targets that can be shared across
#   downstream target branches.


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

pipe_segment_model_spatial_shared <-
  list(
    targets::tar_target(
      description = "Shared spatial-predictor configuration",
      name = "config_spatial_predictors",
      command = base::list(
        use_spatial = get_active_config(
          value = c("model_fitting", "use_spatial")
        ),
        spatial_mode = get_active_config(
          value = c("model_fitting", "spatial_mode")
        ),
        spatial_crs = get_active_config(
          value = c("model_fitting", "spatial_crs")
        ),
        n_mev = get_active_config(
          value = c("model_fitting", "n_mev")
        )
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Project shared coordinates to metric km using ",
        "the configured target CRS"
      ),
      name = "data_coords_projected",
      command = project_coords_to_metric(
        data_coords = data_coords_analysis,
        target_crs = config_spatial_predictors$spatial_crs
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Compute shared 2-D Moran eigenvector maps from ",
        "unique core km locations"
      ),
      name = "data_spatial_mev_core",
      command = {
        if (
          isFALSE(config_spatial_predictors$use_spatial)
        ) {
          NULL
        } else if (
          config_spatial_predictors$spatial_mode == "spatial"
        ) {
          compute_spatial_mev(
            data_coords_projected = data_coords_projected,
            n_mev = config_spatial_predictors$n_mev
          )
        } else {
          NULL
        }
      }
    )
  )

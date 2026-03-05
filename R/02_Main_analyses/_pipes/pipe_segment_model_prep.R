#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            {target} pipe: Preparation for modelling
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe
#   Prepare data and random structure for the HMSC model


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

# Load {here}
library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

# load all project settings
suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

#----------------------------------------------------------#
# 1. pipe definition -----
#----------------------------------------------------------#

pipe_segment_model_prep <-
  list(
    targets::tar_target(
      description = "Scale abiotic predictors; capture attributes",
      name = "data_abiotic_scaled_list",
      command = scale_abiotic_for_fit(
        data_abiotic_wide = data_abiotic_wide
      )
    ),
    targets::tar_target(
      description = paste0(
        "Remove constant taxa from community matrix",
        " (zero standard deviation)"
      ),
      name = "data_community_filtered",
      command = filter_constant_taxa(
        data_community_matrix = data_community_to_fit
      )
    ),
    targets::tar_target(
      description = paste0(
        "Project WGS84 coords to metric km (EPSG:3035)",
        " for spatial modelling"
      ),
      name = "data_coords_projected",
      command = project_coords_to_metric(
        data_coords = data_coords
      )
    ),
    targets::tar_target(
      description = paste0(
        "Compute Moran eigenvector maps (MEMs)",
        " from unique core km locations"
      ),
      name = "data_spatial_mev_core",
      command = compute_spatial_mev(
        data_coords_projected = data_coords_projected,
        n_mev = config.model_fitting$n_mev
      )
    ),
    targets::tar_target(
      description = paste0(
        "Expand MEV core data to per-sample rows",
        " for spatial model term"
      ),
      name = "data_spatial_mev_samples",
      command = prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial_mev_core,
        data_sample_ids = data_sample_ids
      )
    ),
    targets::tar_target(
      description = paste0(
        "Scale spatial MEV predictors; capture attributes",
        " for back-transformation"
      ),
      name = "data_spatial_scaled_list",
      command = scale_spatial_for_fit(
        data_spatial = data_spatial_mev_samples
      )
    ),
    targets::tar_target(
      description = "Validate and assemble data list for fitting",
      name = "data_to_fit",
      command = assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    )
  )

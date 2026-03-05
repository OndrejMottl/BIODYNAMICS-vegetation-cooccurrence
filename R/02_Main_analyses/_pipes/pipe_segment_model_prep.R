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
      description = "Expand dataset-level coords to per-sample rows",
      name = "data_coords_to_fit",
      command = prepare_coords_for_fit(
        data_coords = data_coords,
        data_sample_ids = data_sample_ids
      )
    ),
    targets::tar_target(
      description = "Validate and assemble data list for fitting",
      name = "data_to_fit",
      command = assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_coords_to_fit = data_coords_to_fit
      )
    )
  )

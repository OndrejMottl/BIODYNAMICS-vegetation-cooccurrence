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
      description = "Check and prepare the data for fitting",
      name = "data_to_fit",
      command = check_and_prepare_data_for_fit(
        data_community = data_community_to_fit,
        data_abiotic = data_abiotic_to_fit,
        data_coords = data_coords
      )
    ),
    targets::tar_target(
      description = "Make a random structure for the HMSC model",
      name = "mod_random_structure",
      command = get_random_structure_for_model(
        data = data_to_fit,
        type = c("age", "space"),
        min_knots_distance = config.data_processing$min_distance_of_gpp_knots
      )
    )
  )

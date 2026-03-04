#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             {target} pipe: Sample alignment
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Definition of the alignment pipe segment.
# Computes the canonical (dataset_name, age) sample index used
# by all downstream data-preparation targets.


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
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_alignment <-
  list(
    targets::tar_target(
      description = paste0(
        "Compute the intersecting (dataset_name, age) sample IDs",
        " across community, abiotic, and coordinate data"
      ),
      name = "data_sample_ids",
      command = align_sample_ids(
        data_community_long = data_community_subset,
        data_abiotic_long = data_abiotic_interpolated,
        data_coords = data_coords
      )
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         {target} pipe: Fit data preparation
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Definition of the fit-data preparation pipe segment.
#
# Converts the long-format community and abiotic data into the
# wide matrices required by the model-fitting targets.
#
# Both targets consume `data_sample_ids`, the canonical
# (dataset_name, age) index produced by either
# `pipe_segment_alignment` (full dataset) or
# `pipe_segment_age_filter` (single time-slice).
#
# Usage: include this segment AFTER the alignment / age-filter
# segment and BEFORE `pipe_segment_model_prep`.


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

pipe_segment_fit_data_prep <-
  list(
    targets::tar_target(
      description = "Prepare community data for fitting",
      name = "data_community_to_fit",
      command = prepare_community_for_fit(
        data_community_long = data_community_subset,
        data_sample_ids = data_sample_ids_checked
      )
    ),
    targets::tar_target(
      description = "Widen abiotic data (aligned to sample IDs)",
      name = "data_abiotic_wide",
      command = prepare_abiotic_for_fit(
        data_abiotic_long = data_abiotic_interpolated,
        data_sample_ids = data_sample_ids_checked
      )
    )
  )

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

pipe_segment_sample_alignment <-
  list(
    targets::tar_target(
      description = paste0(
        "Compute the intersecting (dataset_name, age) sample IDs",
        " across community, abiotic, and coordinate data"
      ),
      name = "data_sample_ids",
      command = align_sample_ids(
        data_community_long = data_community_taxa_selected,
        data_abiotic_long = data_abiotic_analysis |>
          dplyr::group_by(dataset_name, age) |>
          dplyr::filter(base::all(!base::is.na(abiotic_value))) |>
          dplyr::ungroup(),
        data_coords = data_coords_analysis
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Fail early if the dataset has fewer than the minimum samples ",
        "before any expensive",
        " data preparation or model fitting"
      ),
      name = "data_sample_ids_count_validated",
      command = validate_sample_count(
        data_sample_ids = data_sample_ids,
        minimum_sample_count = purrr::chuck(
          config_data_processing,
          "min_n_samples"
        )
      )
    )
  )

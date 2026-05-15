#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Modern community preprocessing
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Definition of targets that transform extracted modern community
#   cover/abundance data into Plantae-only, classified community data.


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

pipe_segment_community_prepare_modern <-
  list(
    targets::tar_target(
      description = "Remove non-Plantae taxa from modern community data",
      name = "data_community_plantae",
      command = data_community_long_ages |>
        dplyr::rename(value = "pollen_count") |>
        filter_non_plantae_taxa(
          data_classification_table = data_combined_classification_table
        )
    ),
    targets::tar_target(
      description = "Classify modern community data to configured resolution",
      name = "data_community_classified",
      command = classify_taxonomic_resolution(
        data = data_community_plantae,
        data_classification_table = data_combined_classification_table,
        taxonomic_resolution = config_data_processing$taxonomic_resolution
      )
    )
  )

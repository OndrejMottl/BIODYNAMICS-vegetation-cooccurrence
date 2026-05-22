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
      description = "Report modern community preprocessing QA issues",
      name = "data_modern_quality_report",
      command = make_modern_data_quality_report(
        data_source = data_community_long_ages,
        data_sample_ages = data_sample_ages,
        data_coordinates = data_coords
      )
    ),
    targets::tar_target(
      description = "Deduplicate exact duplicated modern community records",
      name = "data_modern_deduplication",
      command = deduplicate_modern_community_data(
        data_source = data_community_long_ages,
        data_coordinates = data_coords,
        data_quality_report = data_modern_quality_report
      )
    ),
    targets::tar_target(
      description = "Extract deduplicated modern community data",
      name = "data_community_long_ages_deduplicated",
      command = purrr::chuck(
        data_modern_deduplication,
        "data_community"
      )
    ),
    targets::tar_target(
      description = "Aggregate same-prefix colocated modern records",
      name = "data_modern_colocated_preprocessing",
      command = aggregate_colocated_community_records(
        data_source = data_community_long_ages_deduplicated,
        data_coordinates = data_coords,
        data_abiotic_long = data_abiotic_interpolated
      )
    ),
    targets::tar_target(
      description = "Extract community data ready for analysis after modern aggregation",
      name = "data_community_analysis",
      command = purrr::chuck(
        data_modern_colocated_preprocessing,
        "data_community_analysis"
      )
    ),
    targets::tar_target(
      description = "Extract analysis coordinates after modern aggregation",
      name = "data_coords_analysis",
      command = purrr::chuck(
        data_modern_colocated_preprocessing,
        "data_coords_analysis"
      )
    ),
    targets::tar_target(
      description = "Extract abiotic data ready for analysis after modern aggregation",
      name = "data_abiotic_analysis",
      command = purrr::chuck(
        data_modern_colocated_preprocessing,
        "data_abiotic_analysis"
      )
    ),
    targets::tar_target(
      description = "Trace original-to-synthetic modern aggregation mapping",
      name = "data_modern_colocated_aggregation_map",
      command = purrr::chuck(
        data_modern_colocated_preprocessing,
        "data_aggregation_map"
      )
    ),
    targets::tar_target(
      description = paste0(
        "Report cross-database BIEN+sPlot colocations",
        " retained unchanged"
      ),
      name = "data_modern_cross_database_colocations",
      command = purrr::chuck(
        data_modern_colocated_preprocessing,
        "data_cross_database_colocations"
      )
    ),
    targets::tar_target(
      description = "Trace modern duplicate records dropped before modelling",
      name = "data_modern_dropped_duplicate_records",
      command = purrr::chuck(
        data_modern_deduplication,
        "data_dropped_records"
      )
    ),
    targets::tar_target(
      description = "Remove non-Plantae taxa from modern community data",
      name = "data_community_plantae",
      command = data_community_analysis |>
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

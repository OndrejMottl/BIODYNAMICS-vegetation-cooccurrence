#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Paleo community preprocessing
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Definition of targets that transform extracted paleo community
#   data into interpolated, Plantae-only, classified community data.


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

pipe_segment_community_prepare_paleo <-
  list(
    targets::tar_target(
      description = "Transform community counts to proportions",
      name = "data_community_proportions",
      command = make_community_proportions(
        data = data_community_long_ages
      )
    ),
    targets::tar_target(
      description = "Extract age-model uncertainty for fossil cores",
      name = "data_age_uncertainty",
      # Build fossil-pollen plan fresh inside target to avoid serialising
      # the DBI connection
      command = build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = purrr::chuck(config_vegvault_data, "x_lim"),
        y_lim = purrr::chuck(config_vegvault_data, "y_lim"),
        age_lim = purrr::chuck(config_vegvault_data, "age_lim"),
        sel_dataset_type = "fossil_pollen_archive"
      ) |>
        extract_age_uncertainty_from_vegvault(
          data_sample_mapping = data_community_proportions,
          verbose = FALSE
        )
    ),
    targets::tar_target(
      description = "Interpolate community data to specific time step",
      name = "data_community_interpolated",
      command = interpolate_community_data_with_uncertainty(
        data = data_community_proportions,
        data_age_uncertainty = data_age_uncertainty,
        timestep = purrr::chuck(config_data_processing, "time_step"),
        age_min = base::min(config_age_lim),
        age_max = base::max(config_age_lim),
        n_cores = purrr::chuck(config_data_processing, "n_cores")
      )
    ),
    targets::tar_target(
      description = "Remove non-Plantae taxa from community data",
      name = "data_community_plantae",
      command = filter_non_plantae_taxa(
        data = data_community_interpolated,
        data_classification_table = data_combined_classification_table
      )
    ),
    targets::tar_target(
      description = "Classify community data to specific taxonomic resolution",
      name = "data_community_classified",
      command = classify_taxonomic_resolution(
        data = data_community_plantae,
        data_classification_table = data_combined_classification_table,
        taxonomic_resolution = purrr::chuck(
          config_data_processing,
          "taxonomic_resolution"
        )
      )
    ),
    targets::tar_target(
      description = "Paleo: community data ready for downstream analysis",
      name = "data_community_analysis",
      command = data_community_classified
    ),
    targets::tar_target(
      description = "Paleo: raw coordinates as analysis coordinates",
      name = "data_coords_analysis",
      command = data_coords
    ),
    targets::tar_target(
      description = "Paleo: raw abiotic data for analysis",
      name = "data_abiotic_analysis",
      command = data_abiotic_interpolated
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Community data
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to create Community data


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

pipe_target_community_data <-
  list(
    targets::tar_target(
      description = "Extract community data",
      name = "data_community",
      command = get_community_data(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Get community data into long-format",
      name = "data_community_long",
      command = make_community_data_long(data_community)
    ),
    targets::tar_target(
      description = "Get sample ages",
      name = "data_sample_ages",
      command = get_sample_ages(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Add sample ages to community data",
      name = "data_community_long_ages",
      command = add_age_to_samples(data_community_long, data_sample_ages)
    ),
    targets::tar_target(
      description = "Interpolate community data to specific time step",
      name = "data_community_interpolated",
      command = interpolate_community_data(
        data = data_community_long_ages,
        timestep = config.data_processing$time_step,
        age_min = min(config.age_lim),
        age_max = max(config.age_lim)
      )
    ),
    targets::tar_target(
      description = "Make vector of all taxa in community data",
      name = "vec_community_taxa",
      command = get_community_taxa(data_community_long)
    ),
    targets::tar_target(
      description = "Get classification for each taxon",
      name = "data_community_taxa_classification",
      command = get_taxa_classification(vec_community_taxa),
      pattern = map(vec_community_taxa)
    ),
    targets::tar_target(
      description = "Make classification table for community data",
      name = "data_classification_table",
      command = make_classification_table(
        data = data_community_taxa_classification
      )
    ),
    targets::tar_target(
      description = "Classify community data to specific taxonomic resolution",
      name = "data_community_classified",
      command = classify_taxonomic_resolution(
        data = data_community_interpolated,
        data_classification_table = data_classification_table,
        taxonomic_resolution = config.data_processing$taxonomic_resolution
      )
    ),
    targets::tar_target(
      description = "Select number of taxa to include",
      name = "data_community_subset",
      command = select_n_taxa(
        data = data_community_classified,
        n_taxa = config.data_processing$number_of_taxa
      )
    ),
    targets::tar_target(
      description = "Prepare community data for fitting",
      name = "data_community_to_fit",
      command = prepare_data_for_fit(
        data = data_community_subset,
        type = "community"
      )
    )
  )
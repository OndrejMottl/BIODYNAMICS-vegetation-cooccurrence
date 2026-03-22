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

pipe_segment_community_data <-
  list(
    targets::tar_target(
      description = "Extract community data",
      name = "data_community",
      command = {
        # Ensure core-count guard has passed before extracting community data
        force(check_n_cores)
        get_community_data(data_vegvault_extracted)
      }
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
      description = "Transform community counts to proportions",
      name = "data_community_proportions",
      command = make_community_proportions(
        data = data_community_long_ages
      )
    ),
    targets::tar_target(
      description = "Interpolate community data to specific time step",
      name = "data_community_interpolated",
      command = interpolate_community_data(
        data = data_community_proportions,
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
      description = "Track auxiliary classification CSV for changes",
      name = "file_aux_classification_table",
      command = here::here("Data/Input/aux_classification_table.csv"),
      format = "file"
    ),
    targets::tar_target(
      description = "Load auxiliary classification table from CSV",
      name = "data_aux_classification_table",
      command = get_aux_classification_table(
        file_path = file_aux_classification_table
      )
    ),
    targets::tar_target(
      description = "Combine auto and auxiliary classification tables",
      name = "data_combined_classification_table",
      command = combine_classification_tables(
        data_classification_table = data_classification_table,
        data_aux_classification_table = data_aux_classification_table
      )
    ),
    targets::tar_target(
      description = "Identify taxa without classification",
      name = "vec_taxa_without_classification",
      command = get_taxa_without_classification(
        vec_community_taxa = vec_community_taxa,
        data_classification_table = data_combined_classification_table
      )
    ),
    targets::tar_target(
      description = "Build missing-taxa template tibble for inspection",
      name = "data_missing_taxa_template",
      command = tibble::tibble(
        sel_name = vec_taxa_without_classification,
        kingdom = NA_character_,
        phylum = NA_character_,
        class = NA_character_,
        order = NA_character_,
        family = NA_character_,
        genus = NA_character_,
        species = NA_character_
      )
    ),
    targets::tar_target(
      description = "Check all taxa are classified; error if not",
      name = "check_taxa_classification",
      command = {
        force(data_missing_taxa_template)
        check_and_report_missing_taxa(
          vec_taxa_without_classification = vec_taxa_without_classification
        )
      }
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
        taxonomic_resolution = config.data_processing$taxonomic_resolution
      )
    ),
    targets::tar_target(
      description = "Filter rare taxa from community data",
      name = "data_community_rare_filtered",
      command = filter_rare_taxa(
        data = data_community_classified,
        minimal_proportion = config.data_processing$minimal_proportion_of_pollen
      )
    ),
    targets::tar_target(
      description = "Filter taxa not present in enough cores",
      name = "data_community_filtered_cores",
      command = filter_community_by_n_cores(
        data = data_community_rare_filtered,
        min_n_cores = config.data_processing$min_n_cores
      )
    ),
    targets::tar_target(
      description = "Filter taxa not present in enough samples",
      name = "data_community_filtered_samples",
      command = filter_by_n_samples(
        data = data_community_filtered_cores,
        min_n_samples = config.data_processing$min_n_samples
      )
    ),
    targets::tar_target(
      description = "Select number of taxa to include",
      name = "data_community_subset",
      command = select_n_taxa(
        data = data_community_filtered_samples,
        n_taxa = config.data_processing$number_of_taxa
      )
    )
  )

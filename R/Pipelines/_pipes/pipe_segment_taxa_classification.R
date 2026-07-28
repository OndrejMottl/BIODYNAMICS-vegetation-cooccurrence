#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Taxa classification
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Definition of targets that classify taxa in the community
#   data and report missing auxiliary classifications.


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

pipe_segment_taxa_classification <-
  list(
    targets::tar_target(
      description = "Build vector of all taxa in community data",
      name = "vec_community_taxa",
      command = get_community_taxa(data_community_long)
    ),
    targets::tar_target(
      description = "Validate taxa vector before dynamic branching",
      name = "vec_community_taxa_checked",
      command = {
        assertthat::assert_that(
          base::is.character(vec_community_taxa),
          msg = stringr::str_c(
            "`vec_community_taxa` must be a character vector before ",
            "taxa-classification branching."
          )
        )

        assertthat::assert_that(
          base::length(vec_community_taxa) > 0L,
          msg = stringr::str_c(
            "`vec_community_taxa` is empty. This usually indicates ",
            "an upstream failure (for example low-data unit guards)."
          )
        )

        vec_community_taxa
      }
    ),
    targets::tar_target(
      description = "Load classification for each taxon",
      name = "data_community_taxa_classification",
      command = load_taxa_classification(vec_community_taxa_checked),
      pattern = map(vec_community_taxa_checked)
    ),
    targets::tar_target(
      description = "Build classification table for community data",
      name = "data_classification_table",
      command = build_classification_table(
        list_taxa_classifications = data_community_taxa_classification
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
      command = load_auxiliary_classification_table(
        file_auxiliary_classification_table =
          file_aux_classification_table
      )
    ),
    targets::tar_target(
      description = "Build combined automatic and auxiliary classification",
      name = "data_combined_classification_table",
      command = build_combined_classification_table(
        data_classification_table = data_classification_table,
        data_auxiliary_classification_table =
          data_aux_classification_table
      )
    ),
    targets::tar_target(
      description = "Select taxa without classification",
      name = "vec_taxa_without_classification",
      command = select_unclassified_taxa(
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
      description = "Save missing taxa to template CSV",
      name = "file_missing_taxa_template",
      command = save_missing_taxa_template(
        data_missing_taxa = data_missing_taxa_template,
        file_missing_taxa_template = here::here(
          "Data/Input/missing_taxa_template.csv"
        ),
        data_classification_table = data_combined_classification_table
      ),
      format = "file"
    ),
    targets::tar_target(
      description = "Validate that all taxa are classified",
      name = "check_taxa_classification",
      command = validate_taxa_classification_coverage(
        vec_taxa_without_classification = vec_taxa_without_classification,
        file_missing_taxa_template = file_missing_taxa_template
      )
    )
  )

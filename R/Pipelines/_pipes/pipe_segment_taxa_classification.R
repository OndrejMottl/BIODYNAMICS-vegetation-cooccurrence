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
      description = "Make vector of all taxa in community data",
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
      description = "Get classification for each taxon",
      name = "data_community_taxa_classification",
      command = get_taxa_classification(vec_community_taxa_checked),
      pattern = map(vec_community_taxa_checked)
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
      description = "Append missing taxa to template CSV",
      name = "file_missing_taxa_template",
      command = append_missing_taxa_to_template(
        data_missing_taxa = data_missing_taxa_template,
        file_path = here::here(
          "Data/Input/missing_taxa_template.csv"
        ),
        data_classification_table = data_combined_classification_table
      ),
      format = "file"
    ),
    targets::tar_target(
      description = "Check all taxa are classified; error if not",
      name = "check_taxa_classification",
      command = check_and_report_missing_taxa(
        vec_taxa_without_classification = vec_taxa_without_classification,
        file_missing_taxa_template = file_missing_taxa_template
      )
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {target} pipe: Result summary type - age
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to extract summary
#   statistics for species associations for each age slice


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

pipe_segment_result_summary_age <-
  list(
    tarchetypes::tar_combine(
      name = "species_associations_by_age_merged",
      pipe_models_by_age[["number_of_significant_associations"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = "Table of significant associations by age",
      name = "data_species_associations_by_age",
      command = species_associations_by_age_merged %>%
        purrr::map("dataset_name") %>%
        purrr::map("proportion_significant") %>%
        unlist() %>%
        purrr::set_names(
          nm = names(.) %>%
            stringr::str_extract(., "_timeslice_\\d+") %>%
            stringr::str_remove(., "_timeslice_")
        ) %>%
        as.data.frame() %>%
        purrr::set_names("prop_sign_assoc") %>%
        tibble::rownames_to_column("age") %>%
        dplyr::mutate(
          age = as.numeric(age)
        )
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Result summary type
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to extract summary 
#   statistics for species associations


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

pipe_target_result_summary_type <-
  targets::tar_target(
    description = "Table of species associations total",
    name = "data_species_associations_total",
    command = number_of_significant_associations %>%
      purrr::map("proportion_significant") %>%
      unlist() %>%
      purrr::set_names(
        nm = names(.)
      ) %>%
      as.data.frame() %>%
      purrr::set_names("n_sign_assoc") %>%
      tibble::rownames_to_column("type")
  )

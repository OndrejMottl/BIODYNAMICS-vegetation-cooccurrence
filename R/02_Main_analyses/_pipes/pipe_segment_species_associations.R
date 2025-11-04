#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Species associations
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up species associations


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

pipe_segment_species_associations <-
  list(
    targets::tar_target(
      description = "Get species associations",
      name = "species_associations",
      command = get_species_association(mod_hmsc_to_use)
    ),
    targets::tar_target(
      description = "Get number of significant associations",
      name = "number_of_significant_associations",
      command = get_significant_associations(
        species_associations,
        alpha = 0.05
      )
    )
  )

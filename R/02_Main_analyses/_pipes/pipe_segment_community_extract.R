#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Community extraction
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Definition of targets that extract raw community data from
#   VegVault and attach sample ages.


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

pipe_segment_community_extract <-
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
    )
  )

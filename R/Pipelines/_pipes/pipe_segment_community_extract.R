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
      description = "Extract nested community records",
      name = "data_community",
      command = {
        # Ensure core-count guard has passed before extracting community data
        force(validation_available_core_count)
        extract_community_records(
          data_vegvault = data_vegvault_extracted
        )
      }
    ),
    targets::tar_target(
      description = "Reshape community data to long format",
      name = "data_community_long",
      command = reshape_community_to_long(
        data_community = data_community
      )
    ),
    targets::tar_target(
      description = "Extract sample ages",
      name = "data_sample_ages",
      command = extract_sample_ages(
        data_vegvault = data_vegvault_extracted
      )
    ),
    targets::tar_target(
      description = "Join sample ages to community data",
      name = "data_community_long_ages",
      command = join_sample_ages(
        data_records = data_community_long,
        data_sample_ages = data_sample_ages
      )
    )
  )

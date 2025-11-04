#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: VegVault data
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to load VegVault data


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

pipe_segment_vegvault_data <-
  list(
    targets::tar_target(
      description = "Extracted data from VegVault",
      name = "data_vegvault_extracted",
      command = extract_data_from_vegvault(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = config.vegvault_data$x_lim,
        y_lim = config.vegvault_data$y_lim,
        age_lim = config.vegvault_data$age_lim,
        sel_abiotic_var_name = config.vegvault_data$sel_abiotic_var_name,
        sel_dataset_type = config.vegvault_data$sel_dataset_type
      )
    ),
    targets::tar_target(
      description = "Get coordinates of the VegVault data",
      name = "data_coords",
      command = get_coords(data_vegvault_extracted)
    )
  )
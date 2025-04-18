#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                   Main {target} pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the main target pipe, which is run in the `Master.R` file


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

# load all functions
targets::tar_source(
  files = here::here("R/Functions/")
)

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

list(
  targets::tar_target(
    name = "data_vegvault_extracted",
    command = extract_data_from_vegvault(
      path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
      x_lim = get_active_config(value = c("vegvault_data", "x_lim")),
      y_lim = get_active_config(value = c("vegvault_data", "y_lim")),
      age_lim = get_active_config(value = c("vegvault_data", "age_lim")),
      sel_abiotic_var_name = get_active_config(value = c("vegvault_data", "sel_abiotic_var_name")),
      sel_dataset_type = get_active_config(value = c("vegvault_data", "sel_dataset_type"))
    ),
    format = "qs",
  ),
  targets::tar_target(
    name = "data_community",
    command = get_community_data(data_vegvault_extracted),
    format = "qs"
  ),
  targets::tar_target(
    name = "data_community_long",
    command = make_community_data_long(data_community),
    format = "qs"
  ),
  targets::tar_target(
    name = "data_sample_ages",
    command = get_sample_ages(data_vegvault_extracted),
    format = "qs"
  ),
  targets::tar_target(
    name = "data_community_long_ages",
    command = add_age_to_community_data(data_community_long, data_sample_ages),
    format = "qs"
  ),
  targets::tar_target(
    name = "data_community_interpolated",
    command = interpolate_community_data(
      data = data_community_long_ages,
      timestep = get_active_config(
        value = c("data_processing", "time_step")
      )
    ),
    format = "qs"
  )
)

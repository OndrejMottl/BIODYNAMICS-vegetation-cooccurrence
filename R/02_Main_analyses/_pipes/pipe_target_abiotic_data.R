#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Abiotic data
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to create Abiotic data


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

pipe_target_abiotic_data <-
  list(
    targets::tar_target(
      description = "Extract abiotic data",
      name = "data_abiotic",
      command = get_abiotic_data(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Add sample ages to abiotic data",
      name = "data_abiotic_ages",
      command = add_age_to_samples(data_abiotic, data_sample_ages) %>%
        dplyr::select(-sample_name)
    ),
    targets::tar_target(
      description = "Interpolate abiotic data to specific time step",
      name = "data_abiotic_interpolated",
      command = interpolate_data(
        data = data_abiotic_ages,
        value_var = "abiotic_value",
        by = c("dataset_name", "abiotic_variable_name"),
        timestep = config.data_processing$time_step,
        age_min = min(config.age_lim),
        age_max = max(config.age_lim)
      )
    ),
    targets::tar_target(
      description = "Prepare abiotic data for fitting",
      name = "data_abiotic_to_fit",
      command = prepare_data_for_fit(
        data = data_abiotic_interpolated,
        type = "abiotic"
      )
    )
  ) 
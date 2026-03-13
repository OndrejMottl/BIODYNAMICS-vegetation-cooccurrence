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

pipe_segment_abiotic_data <-
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
      description = "Check collinearity of abiotic predictors",
      name = "abiotic_collinearity",
      command = get_predictor_collinearity(data_abiotic_ages)
    ),
    targets::tar_target(
      description = "Select non-collinear abiotic predictors",
      name = "data_abiotic_selected",
      command = select_non_collinear_predictors(
        data_source = data_abiotic_ages,
        collinearity_res = abiotic_collinearity
      )
    ),
    targets::tar_target(
      description = "Interpolate abiotic data to specific time step",
      name = "data_abiotic_interpolated",
      command = interpolate_data(
        data = data_abiotic_selected,
        value_var = "abiotic_value",
        by = c("dataset_name", "abiotic_variable_name"),
        timestep = config.data_processing$time_step,
        age_min = min(config.age_lim),
        age_max = max(config.age_lim)
      )
    )
  ) 
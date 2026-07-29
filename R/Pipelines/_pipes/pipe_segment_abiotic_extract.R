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

pipe_segment_abiotic_extract <-
  list(
    targets::tar_target(
      description = "Extract abiotic data",
      name = "data_abiotic",
      command = extract_abiotic_data(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Join sample ages to abiotic data",
      name = "data_abiotic_ages",
      command = join_sample_ages(
        data_records = data_abiotic,
        data_sample_ages = data_sample_ages
      ) |>
        dplyr::select(-sample_name)
    ),
    targets::tar_target(
      description = "Check collinearity of abiotic predictors",
      name = "abiotic_collinearity",
      command = compute_predictor_collinearity(data_abiotic_ages)
    ),
    targets::tar_target(
      description = "Select non-collinear abiotic predictors",
      name = "data_abiotic_selected",
      command = select_non_collinear_predictors(
        data_source = data_abiotic_ages,
        res_collinearity = abiotic_collinearity
      )
    ),
    targets::tar_target(
      description = "Interpolate abiotic data to specific time step",
      name = "data_abiotic_interpolated",
      command = {
        if (
          base::min(config_age_lim) == base::max(config_age_lim)
        ) {
          data_abiotic_selected |>
            dplyr::filter(age == base::min(config_age_lim))
        } else {
          data_abiotic_selected |>
            validate_abiotic_interpolation_contract(
              grouping_variables = base::c(
                "dataset_name",
                "abiotic_variable_name"
              ),
              age_variable_name = "age"
            ) |>
            interpolate_data(
              value_var = "abiotic_value",
              by = base::c("dataset_name", "abiotic_variable_name"),
              timestep = purrr::chuck(config_data_processing, "time_step"),
              age_min = base::min(config_age_lim),
              age_max = base::max(config_age_lim),
              n_cores = purrr::chuck(config_data_processing, "n_cores")
            )
        }
      }
    )
  )

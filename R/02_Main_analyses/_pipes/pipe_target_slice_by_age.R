#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Age slices
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up Age slices


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

# get the list of expected ages
data_to_map_age <-
  tibble::tibble(
    age = seq(
      from = min(get_active_config(c("vegvault_data", "age_lim"))),
      to = max(get_active_config(c("vegvault_data", "age_lim"))),
      by = get_active_config(c("data_processing", "time_step"))
    ),
    age_name = paste0("timeslice_", age)
  )

pipe_target_models_by_age <-
  # make a branch for each model type (null, full)
  tarchetypes::tar_map(
    values = data_to_map_formula,
    descriptions = "formula_name",
    targets::tar_target(
      description = "Check and prepare the data for fitting",
      name = "data_to_fit",
      command = check_and_prepare_data_for_fit(
        data_community = data_community_to_fit,
        data_abiotic = data_abiotic_to_fit,
        data_coords = data_coords,
        subset_age = age
      )
    ),
    targets::tar_target(
      description = "Make a random structure for the HMSC model",
      name = "mod_random_structure",
      command = get_random_structure_for_model(
        data = data_to_fit,
        type = "space",
        min_knots_distance = config.data_processing$min_distance_of_gpp_knots
      )
    ),
    pipe_target_fit_and_evaluate
  )

pipe_target_models_by_age_with_summary <-
  list(
    pipe_target_models_by_age,
    tarchetypes::tar_combine(
      name = "mod_hmsc_fitted_combined",
      pipe_target_models_by_age[["mod_hmsc_eval"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = "Select either null or full model based on fit",
      name = "mod_hmsc_fitted_selected",
      command = get_better_model_based_on_fit(mod_hmsc_fitted_combined)
    ),
    pipe_target_species_associations
  )

pipe_models_by_age <-
  # make a branch for each age
  tarchetypes::tar_map(
    values = data_to_map_age,
    descriptions = "age_name",
    pipe_target_models_by_age_with_summary
  )

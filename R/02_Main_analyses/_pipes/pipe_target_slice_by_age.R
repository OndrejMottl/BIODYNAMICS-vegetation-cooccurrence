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

pipe_target_models_by_age <-
  list(
    pipe_target_model_prep_by_age,
    targets::tar_target(
      description = "make HMSC model",
      name = "mod_hmsc",
      command = make_hmsc_model(
        data_to_fit = data_to_fit,
        sel_formula = "~ .",
        random_structure = mod_random_structure,
        error_family = "binomial"
      )
    ),
    pipe_target_model_fit,
    targets::tar_target(
      description = "A workaround to select the model for species associations",
      name = "mod_hmsc_to_use",
      command = mod_hmsc_eval
    )
  )

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

pipe_models_by_age <-
  # make a branch for each age
  tarchetypes::tar_map(
    values = data_to_map_age,
    descriptions = "age_name",
    pipe_target_models_by_age,
    pipe_target_species_associations
  )

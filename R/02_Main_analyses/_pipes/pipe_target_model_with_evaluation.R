#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           {target} pipe: Model fitting and evaluation
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up Model fitting
#   and evaluation


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

# get the model formulae to use
data_to_map_formula <-
  tibble::tibble(
    model_formula = c("~ 1", "~ ."),
    formula_name = c("null", "full")
  )

pipe_target_model_full <-
  tarchetypes::tar_map(
    values = data_to_map_formula,
    descriptions = "formula_name",
    targets::tar_target(
      description = "make HMSC model",
      name = "mod_hmsc",
      command = make_hmsc_model(
        data_to_fit = data_to_fit,
        sel_formula = model_formula,
        random_structure = mod_random_structure,
        error_family = "binomial"
      )
    ),
    # list of targets to fit and evaluate the model
    pipe_target_model_fit
  )

pipe_target_model_full_with_evaluation <-
  list(
    pipe_target_model_prep,
    pipe_target_model_full,
    tarchetypes::tar_combine(
      name = "mod_hmsc_fitted_combined",
      pipe_target_model_full[["mod_hmsc_eval"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = "Select either null or full model based on fit",
      name = "mod_hmsc_to_use",
      command = get_better_model_based_on_fit(mod_hmsc_fitted_combined)
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Simple model fitting
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up a simple model fitting


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

pipe_target_model_simple <-
  list(
    pipe_target_model_prep,
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

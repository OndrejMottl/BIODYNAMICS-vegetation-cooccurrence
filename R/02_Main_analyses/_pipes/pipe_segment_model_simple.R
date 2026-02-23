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

pipe_segment_model_simple <-
  list(
    pipe_segment_model_prep,
    targets::tar_target(
      description = "predictor formulae to use for model fitting",
      name = "model_formula",
      command = data_to_fit |>
        purrr::chuck("data_abiotic_to_fit") |>
        make_env_formula()
    ),
    targets::tar_target(
      description = "make JSDM model",
      name = "mod_jsdm",
      command = fit_jsdm_model(
        data_to_fit = data_to_fit,
        sel_formula = model_formula,
        abiotic_method = "linear",
        spatial_method = "linear",
        error_family = "binomial",
        device = "gpu",
        parallel = config.model_fitting$n_cores,
        sampling = config.model_fitting$samples,
        iter = config.model_fitting$samples,
        seed = 900723,
        verbose = FALSE
      )
    ),
    targets::tar_target(
      description = "a workaround target to use the fitted model in the next steps",
      name = "mod_jsdm_to_use",
      command = mod_jsdm
    )
  )

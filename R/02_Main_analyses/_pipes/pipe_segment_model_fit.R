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

pipe_segment_model_fit <-
  list(
    targets::tar_target(
      description = "predictor formulae to use for model fitting",
      name = "model_formula",
      command = data_model_input |>
        purrr::chuck("data_abiotic_to_fit") |>
        make_env_formula(
          use_age = config_model_fitting$use_age_in_formula
        )
    ),
    targets::tar_target(
      description = "make JSDM model",
      name = "model_jsdm",
      command = fit_jsdm_model(
        data_to_fit = data_model_input,
        abiotic_method = "linear",
        sel_abiotic_formula = model_formula,
        spatial_method = if (isTRUE(config_model_fitting$use_spatial)) "linear" else "none",
        sel_spatial_formula = ~ 0 + .,
        error_family = config_model_fitting$error_family,
        device = "gpu",
        parallel = config_model_fitting$n_cores,
        sampling = config_model_fitting$n_sampling,
        iter = config_model_fitting$n_iter,
        step_size = config_model_fitting$n_step_size,
        n_early_stopping = config_model_fitting$n_early_stopping,
        seed = 900723,
        verbose = TRUE,
        compute_se = FALSE
      )
    ),
    targets::tar_target(
      description = paste(
        "compute standard errors for JSDM model post-hoc;",
        "separated from model fitting so that CPU parallelisation",
        "can be used independently of the GPU device setting"
      ),
      name = "model_jsdm_standard_errors",
      command = compute_jsdm_se(
        mod_jsdm = model_jsdm,
        parallel = config_model_fitting$n_cores,
        verbose = TRUE
      )
    ),
    targets::tar_target(
      description = "a workaround target to use the fitted model in the next steps",
      name = "model_jsdm_selected",
      command = model_jsdm_standard_errors
    ),
    targets::tar_target(
      description = "evaluate JSDM model",
      name = "model_evaluation",
      command = evaluate_jsdm(
        mod_jsdm = model_jsdm_selected
      )
    )
  )

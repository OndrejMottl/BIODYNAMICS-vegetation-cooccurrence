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
# Definition of the target pipe, which sets up simple model fitting.


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
      name = "formula_jsdm_environment",
      command = data_model_input |>
        purrr::chuck("data_abiotic_to_fit") |>
        build_jsdm_environment_formula(
          use_age = purrr::chuck(
            config_model_fitting,
            "use_age_in_formula"
          )
        )
    ),
    targets::tar_target(
      description = "make JSDM model",
      name = "mod_jsdm",
      command = if (
        model_regularization_for_fit[["selection_status"]][[1L]] ==
          "full_model_infeasible"
      ) {
        NULL
      } else {
        fit_jsdm_model(
          data_to_fit = data_model_input,
          abiotic_method = "linear",
          sel_abiotic_formula = formula_jsdm_environment,
          spatial_method = if (
            base::isTRUE(config_model_fitting[["use_spatial"]])
          ) {
            "linear"
          } else {
            "none"
          },
          sel_spatial_formula = ~ 0 + .,
          error_family = config_model_fitting[["error_family"]],
          device = "gpu",
          parallel = config_model_fitting[["n_cores"]],
          sampling = config_model_fitting[["n_sampling"]],
          iter = config_model_fitting[["n_iter"]],
          step_size = config_model_fitting[["n_step_size"]],
          n_early_stopping =
            config_model_fitting[["n_early_stopping"]],
          seed = 900723,
          verbose = TRUE,
          compute_se = FALSE,
          alpha_cov = model_regularization_for_fit[["alpha_cov"]][[1L]],
          alpha_coef = model_regularization_for_fit[["alpha_coef"]][[1L]],
          alpha_spatial =
            model_regularization_for_fit[["alpha_spatial"]][[1L]],
          lambda_cov =
            model_regularization_for_fit[["lambda_cov"]][[1L]],
          lambda_coef =
            model_regularization_for_fit[["lambda_coef"]][[1L]],
          lambda_spatial =
            model_regularization_for_fit[["lambda_spatial"]][[1L]]
        )
      }
    ),
    targets::tar_target(
      description = paste(
        "compute standard errors for JSDM model post-hoc;",
        "separated from model fitting so that CPU parallelisation",
        "can be used independently of the GPU device setting"
      ),
      name = "mod_jsdm_with_standard_errors",
      command = if (
        base::is.null(mod_jsdm)
      ) {
        NULL
      } else {
        compute_jsdm_se(
          mod_jsdm = mod_jsdm,
          parallel = config_model_fitting[["n_cores"]],
          verbose = TRUE
        )
      }
    ),
    targets::tar_target(
      description = stringr::str_c(
        "a workaround target to use the fitted model in the next steps"
      ),
      name = "mod_jsdm_selected",
      command = mod_jsdm_with_standard_errors
    ),
    targets::tar_target(
      description = "evaluate JSDM model",
      name = "list_jsdm_evaluation_fitted",
      command = if (
        base::is.null(mod_jsdm_selected)
      ) {
        NULL
      } else {
        evaluate_jsdm(
          mod_jsdm = mod_jsdm_selected
        )
      }
    )
  )

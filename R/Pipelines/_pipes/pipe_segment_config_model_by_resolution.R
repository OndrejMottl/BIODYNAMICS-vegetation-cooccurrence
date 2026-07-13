#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     {targets} pipe: resolution-specific model-fitting config
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines a single resolution-aware `config_model_fitting`
#   target for use INSIDE tarchetypes::tar_map().
#
# PURPOSE
#   pipeline_paleo_spatial_resolution.R maps over resolution_id values
#   ("genus", "family", "functional_type"). Each resolution branch may
#   have different convergence parameters (n_iter, n_sampling,
#   n_step_size, n_early_stopping) stored in model tuning CSVs.
#   This segment builds a per-resolution config_model_fitting
#   by calling get_model_tuning_params() with the active resolution
#   value substituted by tarchetypes::tar_map().
#
# When inside tar_map() this segment produces:
#   config_model_fitting_genus
#   config_model_fitting_family
#   config_model_fitting_functional_type
# which shadow the shared config_model_fitting (from
#   pipe_segment_config_common.R) only within each resolution branch.
#
# All non-fitting configuration targets (config_data_processing,
#   config_x_lim, etc.) remain shared and are NOT redefined here.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_config_model_by_resolution <-
  list(
    targets::tar_target(
      description = stringr::str_c(
        "Resolution-specific model fitting configuration.",
        " Reads fitting params from the resolution-specific columns",
        " from the model tuning CSV via get_model_tuning_params().",
        " resolution_id is injected by tarchetypes::tar_map()."
      ),
      name = "config_model_fitting",
      command = {
        base::list(
          n_cores = get_active_config(
            value = c("model_fitting", "n_cores")
          ),
          n_iter = get_model_tuning_param_for_scale_and_resolution(
            param_id = "n_iter",
            resolution_id = resolution_id
          ),
          n_sampling = get_model_tuning_param_for_scale_and_resolution(
            param_id = "n_sampling",
            resolution_id = resolution_id
          ),
          n_step_size = get_model_tuning_param_for_scale_and_resolution(
            param_id = "n_step_size",
            resolution_id = resolution_id
          ),
          n_early_stopping =
            get_model_tuning_param_for_scale_and_resolution(
              param_id = "n_early_stopping",
              resolution_id = resolution_id
            ),
          n_samples_anova = get_model_tuning_param_for_scale_and_resolution(
            param_id = "n_samples_anova",
            resolution_id = resolution_id
          ),
          n_mev = get_active_config(
            value = c("model_fitting", "n_mev")
          ),
          error_family = config_error_family,
          spatial_crs = get_active_config(
            value = c("model_fitting", "spatial_crs")
          ),
          spatial_mode = get_active_config(
            value = c("model_fitting", "spatial_mode")
          ),
          use_spatial = get_active_config(
            value = c("model_fitting", "use_spatial")
          ),
          use_age_in_formula = get_active_config(
            value = c("model_fitting", "use_age_in_formula")
          ),
          age_scale_mode = get_active_config(
            value = c("model_fitting", "age_scale_mode")
          ),
          cross_validation = get_active_config(
            value = c("model_fitting", "cross_validation")
          )
        )
      },
      cue = targets::tar_cue(mode = "always")
    )
  )

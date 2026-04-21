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
# Defines a single resolution-aware `config.model_fitting`
#   target for use INSIDE tarchetypes::tar_map().
#
# PURPOSE
#   pipeline_spatial_resolution.R maps over tax_res values
#   ("family", "functional_type").  Each resolution branch may
#   have different convergence parameters (n_iter, n_sampling,
#   n_step_size, n_early_stopping) stored in the spatial grid
#   CSV.  This segment builds a per-resolution config.model_fitting
#   by calling get_spatial_model_params() with tax_res = tax_res,
#   where tax_res is substituted by tarchetypes::tar_map().
#
# When inside tar_map() this segment produces:
#   config.model_fitting_family
#   config.model_fitting_functional_type
# which shadow the shared config.model_fitting (from
#   pipe_segment_config.R) only within each resolution branch.
#
# All non-fitting configuration targets (config.data_processing,
#   config.x_lim, etc.) remain shared and are NOT redefined here.


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

pipe_segment_config_resolution <-
  list(
    targets::tar_target(
      description = stringr::str_c(
        "Resolution-specific model fitting configuration.",
        " Reads fitting params from the resolution-specific columns",
        " in spatial_grid.csv via get_spatial_model_params(tax_res).",
        " tax_res is injected by tarchetypes::tar_map()."
      ),
      name = "config.model_fitting",
      command = {
        sel_scale_id <-
          get_scale_id_from_store()

        params <-
          if (!base::is.null(sel_scale_id)) {
            get_spatial_model_params(
              scale_id = sel_scale_id,
              tax_res = tax_res
            )
          } else {
            base::list(
              n_iter = get_active_config(
                value = c("model_fitting", "n_iter")
              ),
              n_step_size = get_active_config(
                value = c("model_fitting", "n_step_size")
              ),
              n_sampling = get_active_config(
                value = c("model_fitting", "n_sampling")
              ),
              n_samples_anova = get_active_config(
                value = c("model_fitting", "n_samples_anova")
              ),
              n_early_stopping = get_active_config(
                value = c("model_fitting", "n_early_stopping")
              )
            )
          }

        base::list(
          n_cores = get_active_config(
            value = c("model_fitting", "n_cores")
          ),
          n_iter = purrr::chuck(params, "n_iter"),
          n_sampling = purrr::chuck(params, "n_sampling"),
          n_step_size = purrr::pluck(params, "n_step_size"),
          n_early_stopping = purrr::pluck(
            params, "n_early_stopping"
          ),
          n_samples_anova = purrr::chuck(
            params, "n_samples_anova"
          ),
          n_mev = get_active_config(
            value = c("model_fitting", "n_mev")
          ),
          error_family = get_active_config(
            value = c("model_fitting", "error_family")
          ),
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
          )
        )
      },
      cue = targets::tar_cue(mode = "always")
    )
  )

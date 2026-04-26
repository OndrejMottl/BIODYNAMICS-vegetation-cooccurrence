#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        {target} pipe: shared model-fitting configuration
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines the shared (non-resolution-specific) model-fitting
#   configuration targets:  scalar params read from config.yml /
#   spatial_grid.csv and the aggregated `config.model_fitting`
#   list-target.
#
# WHEN TO INCLUDE
#   Include this segment in pipelines where a SINGLE shared
#   `config.model_fitting` is consumed by ALL model targets
#   (i.e. tar_map() is not used to produce per-resolution
#   config.model_fitting_* variants):
#     - pipeline_basic.R
#     - pipeline_test_resolution.R
#     - pipeline_time.R
#
#   Do NOT include in pipeline_spatial_resolution.R, which
#   instead sources pipe_segment_config_resolution.R inside
#   tar_map() to produce resolution-specific
#   config.model_fitting_family / _functional_type / _genus
#   targets.  Including both would leave the shared
#   config.model_fitting isolated (no downstream consumers).


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

pipe_segment_config_model_fitting <-
  list(
    targets::tar_target(
      description = "Configuration for model fitting - n_cores",
      name = "config.n_cores",
      command = get_active_config(
        value = c("model_fitting", "n_cores")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " number of training iterations"
      ),
      name = "config.n_iter",
      command = {
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_model_params(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("n_iter")
        } else {
          get_active_config(
            value = c("model_fitting", "n_iter")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " Monte Carlo samples per epoch"
      ),
      name = "config.n_sampling",
      command = {
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_model_params(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("n_sampling")
        } else {
          get_active_config(
            value = c("model_fitting", "n_sampling")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " SGD mini-batch size (NULL = auto 10% of sites)"
      ),
      name = "config.n_step_size",
      command = {
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_model_params(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("n_step_size")
        } else {
          get_active_config(
            value = c("model_fitting", "n_step_size")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " early stopping patience (epochs without improvement)"
      ),
      name = "config.n_early_stopping",
      command = {
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_model_params(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("n_early_stopping")
        } else {
          get_active_config(
            value = c("model_fitting", "n_early_stopping")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " Monte Carlo samples for ANOVA variation partitioning"
      ),
      name = "config.n_samples_anova",
      command = {
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_model_params(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("n_samples_anova")
        } else {
          get_active_config(
            value = c("model_fitting", "n_samples_anova")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " number of Moran eigenvectors"
      ),
      name = "config.n_mev",
      command = get_active_config(
        value = c("model_fitting", "n_mev")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    # config.error_family is defined in pipe_segment_config.R so it is
    #   available to all pipelines including pipeline_spatial_resolution.R
    #   (which does not source this file). Referenced as a target dep below.
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - spatial CRS",
        " as an EPSG code (e.g. 3035 for ETRS89-LAEA Europe)"
      ),
      name = "config.spatial_crs",
      command = get_active_config(
        value = c("model_fitting", "spatial_crs")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - spatial mode:",
        " 'spatial' (2-D MEVs) or",
        " 'spatiotemporal' (3-D MEVs)"
      ),
      name = "config.spatial_mode",
      command = get_active_config(
        value = c("model_fitting", "spatial_mode")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - use spatial component:",
        " TRUE to include MEV spatial predictors, FALSE to omit"
      ),
      name = "config.use_spatial",
      command = get_active_config(
        value = c("model_fitting", "use_spatial")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - use age in formula:",
        " TRUE for (bio * age) interaction, FALSE for additive only"
      ),
      name = "config.use_age_in_formula",
      command = get_active_config(
        value = c("model_fitting", "use_age_in_formula")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting",
      name = "config.model_fitting",
      command = list(
        n_cores = config.n_cores,
        n_iter = config.n_iter,
        n_sampling = config.n_sampling,
        n_step_size = config.n_step_size,
        n_early_stopping = config.n_early_stopping,
        n_samples_anova = config.n_samples_anova,
        n_mev = config.n_mev,
        error_family = config.error_family,
        spatial_crs = config.spatial_crs,
        spatial_mode = config.spatial_mode,
        use_spatial = config.use_spatial,
        use_age_in_formula = config.use_age_in_formula
      )
    )
  )

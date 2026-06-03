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
#   model tuning CSVs and the aggregated `config_model_fitting`
#   list-target.
#
# WHEN TO INCLUDE
#   Include this segment in pipelines where a SINGLE shared
#   `config_model_fitting` is consumed by ALL model targets
#   (i.e. tar_map() is not used to produce per-resolution
#   config_model_fitting_* variants):
#     - pipeline_paleo_core.R
#     - pipeline_paleo_resolution_test.R
#     - pipeline_paleo_temporal.R
#
#   Do NOT include in pipeline_paleo_spatial_resolution.R, which
#   instead sources pipe_segment_config_model_by_resolution.R inside
#   tar_map() to produce resolution-specific
#   config_model_fitting_family / _functional_type / _genus
#   targets.  Including both would leave the shared
#   config_model_fitting isolated (no downstream consumers).


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

pipe_segment_config_model <-
  list(
    targets::tar_target(
      description = "Configuration for model fitting - n_cores",
      name = "config_n_cores",
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
      name = "config_n_iter",
      command = get_model_tuning_param_for_scale_and_resolution(
        "n_iter"
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " Monte Carlo samples per epoch"
      ),
      name = "config_n_sampling",
      command = get_model_tuning_param_for_scale_and_resolution(
        "n_sampling"
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " SGD mini-batch size (NULL = auto 10% of sites)"
      ),
      name = "config_n_step_size",
      command = get_model_tuning_param_for_scale_and_resolution(
        "n_step_size"
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " early stopping patience (epochs without improvement)"
      ),
      name = "config_n_early_stopping",
      command = get_model_tuning_param_for_scale_and_resolution(
        "n_early_stopping"
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " Monte Carlo samples for ANOVA variation partitioning"
      ),
      name = "config_n_samples_anova",
      command = get_model_tuning_param_for_scale_and_resolution(
        "n_samples_anova"
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " number of Moran eigenvectors"
      ),
      name = "config_n_mev",
      command = get_active_config(
        value = c("model_fitting", "n_mev")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    # config_error_family is defined in pipe_segment_config_common.R so it is
    #   available to all pipelines including pipeline_paleo_spatial_resolution.R
    #   (which does not source this file). Referenced as a target dep below.
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - spatial CRS",
        " as an EPSG code (e.g. 3035 for ETRS89-LAEA Europe)"
      ),
      name = "config_spatial_crs",
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
      name = "config_spatial_mode",
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
      name = "config_use_spatial",
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
      name = "config_use_age_in_formula",
      command = get_active_config(
        value = c("model_fitting", "use_age_in_formula")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - age scaling mode:",
        " 'z_score' for production fitting, 'center' for legacy checks"
      ),
      name = "config_age_scale_mode",
      command = get_active_config(
        value = c("model_fitting", "age_scale_mode")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting",
      name = "config_model_fitting",
      command = list(
        n_cores = config_n_cores,
        n_iter = config_n_iter,
        n_sampling = config_n_sampling,
        n_step_size = config_n_step_size,
        n_early_stopping = config_n_early_stopping,
        n_samples_anova = config_n_samples_anova,
        n_mev = config_n_mev,
        error_family = config_error_family,
        spatial_crs = config_spatial_crs,
        spatial_mode = config_spatial_mode,
        use_spatial = config_use_spatial,
        use_age_in_formula = config_use_age_in_formula,
        age_scale_mode = config_age_scale_mode
      )
    )
  )

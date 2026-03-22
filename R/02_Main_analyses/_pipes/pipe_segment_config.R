#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: configuration
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to load project configurations


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

pipe_segment_config <-
  list(
    targets::tar_target(
      description = "Configuration for VegVault data extraction - xlim",
      name = "config.x_lim",
      command = {
        # R_SPATIAL_ID set → spatial scale analysis (CSV catalogue)
        # R_SPATIAL_ID unset → named project (YAML config)
        spatial_id <- Sys.getenv("R_SPATIAL_ID")
        if (nchar(spatial_id) > 0) {
          get_spatial_window(scale_id = spatial_id)$x_lim
        } else {
          get_active_config(
            value = c("vegvault_data", "x_lim")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - ylim",
      name = "config.y_lim",
      command = {
        spatial_id <- Sys.getenv("R_SPATIAL_ID")
        if (nchar(spatial_id) > 0) {
          get_spatial_window(scale_id = spatial_id)$y_lim
        } else {
          get_active_config(
            value = c("vegvault_data", "y_lim")
          )
        }
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - agelim",
      name = "config.age_lim",
      command = get_active_config(
        value = c("vegvault_data", "age_lim")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - abiotic variable name",
      name = "config.sel_abiotic_var_name",
      command = get_active_config(
        value = c("vegvault_data", "sel_abiotic_var_name")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - dataset type",
      name = "config.sel_dataset_type",
      command = get_active_config(
        value = c("vegvault_data", "sel_dataset_type")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - dataset type",
      name = "config.vegvault_data",
      command = list(
        x_lim = config.x_lim,
        y_lim = config.y_lim,
        age_lim = config.age_lim,
        sel_abiotic_var_name = config.sel_abiotic_var_name,
        sel_dataset_type = config.sel_dataset_type
      )
    ),
    #--------------------------------------------------#
    targets::tar_target(
      description = "Configuration for data processing - time step",
      name = "config.time_step",
      command = get_active_config(
        value = c("data_processing", "time_step")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - minimal proportion of pollen",
      name = "config.minimal_proportion_of_pollen",
      command = get_active_config(
        value = c("data_processing", "minimal_proportion_of_pollen")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - number of taxa",
      name = "config.number_of_taxa",
      command = get_active_config(
        value = c("data_processing", "number_of_taxa")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - taxonomic resolution",
      name = "config.taxonomic_resolution",
      command = get_active_config(
        value = c("data_processing", "taxonomic_resolution")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - min n cores",
      name = "config.min_n_cores",
      command = get_active_config(
        value = c("data_processing", "min_n_cores")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - min n samples",
      name = "config.min_n_samples",
      command = get_active_config(
        value = c("data_processing", "min_n_samples")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing",
      name = "config.data_processing",
      command = list(
        time_step = config.time_step,
        number_of_taxa = config.number_of_taxa,
        minimal_proportion_of_pollen = config.minimal_proportion_of_pollen,
        taxonomic_resolution = config.taxonomic_resolution,
        min_n_cores = config.min_n_cores,
        min_n_samples = config.min_n_samples
      )
    ),
    #--------------------------------------------------#
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
      command = get_active_config(
        value = c("model_fitting", "n_iter")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " Monte Carlo samples per epoch"
      ),
      name = "config.n_sampling",
      command = get_active_config(
        value = c("model_fitting", "n_sampling")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " SGD mini-batch size (NULL = auto 10% of sites)"
      ),
      name = "config.n_step_size",
      command = get_active_config(
        value = c("model_fitting", "n_step_size")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting -",
        " Monte Carlo samples for ANOVA variation partitioning"
      ),
      name = "config.n_samples_anova",
      command = get_active_config(
        value = c("model_fitting", "n_samples_anova")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting - number of Moran eigenvectors",
      name = "config.n_mev",
      command = get_active_config(
        value = c("model_fitting", "n_mev")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - error family",
        " (e.g. 'binomial' for presence-absence)"
      ),
      name = "config.error_family",
      command = get_active_config(
        value = c("model_fitting", "error_family")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
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

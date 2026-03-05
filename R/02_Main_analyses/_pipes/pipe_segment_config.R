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
      command = get_active_config(
        value = c("vegvault_data", "x_lim")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - ylim",
      name = "config.y_lim",
      command = get_active_config(
        value = c("vegvault_data", "y_lim")
      ),
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
      description = "Configuration for data processing - minimum distance of GPP knots",
      name = "config.min_distance_of_gpp_knots",
      command = get_active_config(
        value = c("data_processing", "min_distance_of_gpp_knots")
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
      description = "Configuration for data processing",
      name = "config.data_processing",
      command = list(
        time_step = config.time_step,
        number_of_taxa = config.number_of_taxa,
        minimal_proportion_of_pollen = config.minimal_proportion_of_pollen,
        taxonomic_resolution = config.taxonomic_resolution,
        min_distance_of_gpp_knots = config.min_distance_of_gpp_knots
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
      description = "Configuration for model fitting - number of samples",
      name = "config.n_samples",
      command = get_active_config(
        value = c("model_fitting", "samples")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting - thin",
      name = "config.n_thin",
      command = get_active_config(
        value = c("model_fitting", "thin")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting - transient",
      name = "config.n_transient",
      command = get_active_config(
        value = c("model_fitting", "transient")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting - verbose",
      name = "config.samples_verbose",
      command = get_active_config(
        value = c("model_fitting", "samples_verbose")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for model fitting - cross-validation",
      name = "config.cross_validation_folds",
      command = get_active_config(
        value = c("model_fitting", "cross_validation_folds")
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
      description = "Configuration for model fitting",
      name = "config.model_fitting",
      command = list(
        n_cores = config.n_cores,
        samples = config.n_samples,
        thin = config.n_thin,
        transient = config.n_transient,
        samples_verbose = config.samples_verbose,
        cross_validation_folds = config.cross_validation_folds,
        n_mev = config.n_mev
      )
    )
  )

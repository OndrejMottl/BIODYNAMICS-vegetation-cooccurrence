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

pipe_segment_config_common <-
  list(
    targets::tar_target(
      description = "Configuration for VegVault data extraction - xlim",
      name = "config_x_lim",
      command = {
        # Spatial pipeline -> scale_id encoded in store path
        # Named project -> returns NULL, falls back to config.yml
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_window(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("x_lim")
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
      name = "config_y_lim",
      command = {
        sel_scale_id <- get_scale_id_from_store()
        if (
          !is.null(sel_scale_id)
        ) {
          get_spatial_window(
            scale_id = sel_scale_id
          ) |>
            purrr::chuck("y_lim")
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
      name = "config_age_lim",
      command = get_active_config(
        value = c("vegvault_data", "age_lim")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - abiotic variable name",
      name = "config_sel_abiotic_var_name",
      command = get_active_config(
        value = c("vegvault_data", "sel_abiotic_var_name")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - dataset type",
      name = "config_sel_dataset_type",
      command = get_active_config(
        value = c("vegvault_data", "sel_dataset_type")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for VegVault data extraction - dataset type",
      name = "config_vegvault_data",
      command = list(
        x_lim = config_x_lim,
        y_lim = config_y_lim,
        age_lim = config_age_lim,
        sel_abiotic_var_name = config_sel_abiotic_var_name,
        sel_dataset_type = config_sel_dataset_type
      )
    ),
    #--------------------------------------------------#
    targets::tar_target(
      description = "Configuration for data processing - time step",
      name = "config_time_step",
      command = get_active_config(
        value = c("data_processing", "time_step")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - minimal proportion of pollen",
      name = "config_minimal_proportion_of_pollen",
      command = get_active_config(
        value = c("data_processing", "minimal_proportion_of_pollen")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - number of taxa",
      name = "config_number_of_taxa",
      command = get_active_config(
        value = c("data_processing", "number_of_taxa")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - taxonomic resolution",
      name = "config_taxonomic_resolution",
      command = get_active_config(
        value = c("data_processing", "taxonomic_resolution")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - min n cores",
      name = "config_min_n_cores",
      command = get_active_config(
        value = c("data_processing", "min_n_cores")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - n cores",
      name = "config_data_n_cores",
      command = get_active_config(
        value = c("data_processing", "n_cores")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing - min n samples",
      name = "config_min_n_samples",
      command = get_active_config(
        value = c("data_processing", "min_n_samples")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = paste0(
        "Configuration for data processing -",
        " minimum number of taxa to run model"
      ),
      name = "config_min_n_taxa",
      command = get_active_config(
        value = c("data_processing", "min_n_taxa")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Configuration for data processing",
      name = "config_data_processing",
      command = list(
        time_step = config_time_step,
        number_of_taxa = config_number_of_taxa,
        minimal_proportion_of_pollen = config_minimal_proportion_of_pollen,
        taxonomic_resolution = config_taxonomic_resolution,
        min_n_cores = config_min_n_cores,
        n_cores = config_data_n_cores,
        min_n_samples = config_min_n_samples,
        min_n_taxa = config_min_n_taxa
      )
    ),
    #--------------------------------------------------#
    # config_error_family is kept here (not in
    #   pipe_segment_config_model.R) because
    #   pipe_segment_ft_classification_continental.R references it as a
    #   direct target dependency from outside tar_map().
    targets::tar_target(
      description = paste0(
        "Configuration for model fitting - error family",
        " (e.g. 'binomial' for presence-absence)"
      ),
      name = "config_error_family",
      command = get_active_config(
        value = c("model_fitting", "error_family")
      ),
      cue = targets::tar_cue(mode = "always")
    )
  )

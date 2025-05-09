#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                   Main {target} pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the main target pipe, which is run in the `Master.R` file


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

# load all functions
targets::tar_source(
  files = here::here("R/Functions/")
)

# set seed for reproducibility
targets::tar_option_set(
  seed = get_active_config("seed")
)

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

list(
  #--------------------------------------------------#
  ## Configurations -----
  #--------------------------------------------------#
  targets::tar_target(
    description = "Configuration for VegVault data extraction - xlim",
    name = "config.x_lim",
    command = get_active_config(
      value = c("vegvault_data", "x_lim")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for VegVault data extraction - ylim",
    name = "config.y_lim",
    command = get_active_config(
      value = c("vegvault_data", "y_lim")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for VegVault data extraction - agelim",
    name = "config.age_lim",
    command = get_active_config(
      value = c("vegvault_data", "age_lim")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for VegVault data extraction - abiotic variable name",
    name = "config.sel_abiotic_var_name",
    command = get_active_config(
      value = c("vegvault_data", "sel_abiotic_var_name")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for VegVault data extraction - dataset type",
    name = "config.sel_dataset_type",
    command = get_active_config(
      value = c("vegvault_data", "sel_dataset_type")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
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
    ),
    format = "qs"
  ),
  #--------------------------------------------------#
  targets::tar_target(
    description = "Configuration for data processing - time step",
    name = "config.time_step",
    command = get_active_config(
      value = c("data_processing", "time_step")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for data processing - number of taxa",
    name = "config.number_of_taxa",
    command = get_active_config(
      value = c("data_processing", "number_of_taxa")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for data processing - minimum distance of GPP knots",
    name = "config.min_distance_of_gpp_knots",
    command = get_active_config(
      value = c("data_processing", "min_distance_of_gpp_knots")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for data processing",
    name = "config.data_processing",
    command = list(
      time_step = config.time_step,
      number_of_taxa = config.number_of_taxa,
      min_distance_of_gpp_knots = config.min_distance_of_gpp_knots
    ),
    format = "qs"
  ),
  #--------------------------------------------------#
  targets::tar_target(
    description = "Configuration for model fitting - number of samples",
    name = "config.n_samples",
    command = get_active_config(
      value = c("model_fitting", "samples")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for model fitting - thin",
    name = "config.n_thin",
    command = get_active_config(
      value = c("model_fitting", "thin")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for model fitting - transient",
    name = "config.n_transient",
    command = get_active_config(
      value = c("model_fitting", "transient")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for model fitting - verbose",
    name = "config.samples_verbose",
    command = get_active_config(
      value = c("model_fitting", "samples_verbose")
    ),
    cue = targets::tar_cue(mode = "always"),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for model fitting",
    name = "config.model_fitting",
    command = list(
      samples = config.n_samples,
      thin = config.n_thin,
      transient = config.n_transient,
      samples_verbose = config.samples_verbose
    ),
    format = "qs"
  ),
  #--------------------------------------------------#
  ## VegVault data -----
  #--------------------------------------------------#
  targets::tar_target(
    description = "Extracted data from VegVault",
    name = "data_vegvault_extracted",
    command = extract_data_from_vegvault(
      path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
      x_lim = config.vegvault_data$x_lim,
      y_lim = config.vegvault_data$y_lim,
      age_lim = config.vegvault_data$age_lim,
      sel_abiotic_var_name = config.vegvault_data$sel_abiotic_var_name,
      sel_dataset_type = config.vegvault_data$sel_dataset_type
    ),
    format = "qs",
  ),
  targets::tar_target(
    description = "Get coordinates of the VegVault data",
    name = "data_coords",
    command = get_coords(data_vegvault_extracted),
    format = "qs"
  ),
  #--------------------------------------------------#
  ## Community data -----
  #--------------------------------------------------#
  targets::tar_target(
    description = "Extract community data",
    name = "data_community",
    command = get_community_data(data_vegvault_extracted),
    format = "qs"
  ),
  targets::tar_target(
    description = "Get community data into long-format",
    name = "data_community_long",
    command = make_community_data_long(data_community),
    format = "qs"
  ),
  targets::tar_target(
    description = "Get sample ages",
    name = "data_sample_ages",
    command = get_sample_ages(data_vegvault_extracted),
    format = "qs"
  ),
  targets::tar_target(
    description = "Add sample ages to community data",
    name = "data_community_long_ages",
    command = add_age_to_samples(data_community_long, data_sample_ages),
    format = "qs"
  ),
  targets::tar_target(
    description = "Interpolate community data to specific time step",
    name = "data_community_interpolated",
    command = interpolate_community_data(
      data = data_community_long_ages,
      timestep = config.data_processing$time_step
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "Select number of taxa to include",
    name = "data_community_subset",
    command = select_n_taxa(
      data = data_community_interpolated,
      n_taxa = config.data_processing$number_of_taxa
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "Prepare community data for fitting",
    name = "data_community_to_fit",
    command = prepare_data_for_fit(
      data = data_community_subset,
      type = "community"
    ),
    format = "qs"
  ),
  #--------------------------------------------------#
  ## Abiotic data -----
  #--------------------------------------------------#
  targets::tar_target(
    description = "Extract abiotic data",
    name = "data_abiotic",
    command = get_abiotic_data(data_vegvault_extracted),
    format = "qs"
  ),
  targets::tar_target(
    description = "Add sample ages to abiotic data",
    name = "data_abiotic_ages",
    command = add_age_to_samples(data_abiotic, data_sample_ages) %>%
      dplyr::select(-sample_name),
    format = "qs"
  ),
  targets::tar_target(
    description = "Interpolate abiotic data to specific time step",
    name = "data_abiotic_interpolated",
    command = interpolate_data(
      data = data_abiotic_ages,
      value_var = "abiotic_value",
      by = c("dataset_name", "abiotic_variable_name"),
      timestep = config.data_processing$time_step
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "Prepare abiotic data for fitting",
    name = "data_abiotic_to_fit",
    command = prepare_data_for_fit(
      data = data_abiotic_interpolated,
      type = "abiotic"
    ),
    format = "qs"
  ),
  #--------------------------------------------------#
  ## Model fitting -----
  #--------------------------------------------------#
  targets::tar_target(
    description = "Check and prepare the data for fitting",
    name = "data_to_fit",
    command = check_and_prepare_data_for_fit(
      data_community = data_community_to_fit,
      data_abiotic = data_abiotic_to_fit,
      data_coords = data_coords
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "Make a random structure for the HMSC model",
    name = "mod_random_structure",
    command = get_random_structure_for_model(
      data = data_to_fit,
      min_knots_distance = config.data_processing$min_distance_of_gpp_knots
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "make HMSC model",
    name = "mod_hmsc",
    command = make_hmsc_model(
      data_to_fit = data_to_fit,
      random_structure = mod_random_structure,
      error_family = "binomial"
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "Fit the HMSC model",
    name = "mod_hmsc_fitted",
    command = fit_hmsc_model(
      mod_hmsc = mod_hmsc,
      n_chains = parallelly::availableCores() - 1,
      n_parallel = parallelly::availableCores() - 1,
      n_samples = config.model_fitting$samples,
      n_thin = config.model_fitting$thin,
      n_transient = config.model_fitting$transient,
      n_samples_verbose = config.model_fitting$samples_verbose
    ),
    format = "qs"
  )
)

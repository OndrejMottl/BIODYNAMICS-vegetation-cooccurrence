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

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

list(
  #--------------------------------------------------#
  ## Configurations -----
  #--------------------------------------------------#
  targets::tar_target(
    description = "Configuration for VegVault data extraction",
    name = "config.vegvault_data",
    command = list(
      x_lim = get_active_config(
        value = c("vegvault_data", "x_lim")
      ),
      y_lim = get_active_config(
        value = c("vegvault_data", "y_lim")
      ),
      age_lim = get_active_config(
        value = c("vegvault_data", "age_lim")
      ),
      sel_abiotic_var_name = get_active_config(
        value = c("vegvault_data", "sel_abiotic_var_name")
      ),
      sel_dataset_type = get_active_config(
        value = c("vegvault_data", "sel_dataset_type")
      )
    ),
    format = "qs"
  ),
  targets::tar_target(
    description = "Configuration for data processing",
    name = "config.data_processing",
    command = list(
      time_step = get_active_config(
        value = c("data_processing", "time_step")
      ),
      number_of_taxa = get_active_config(
        value = c("data_processing", "number_of_taxa")
      )
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
    description = "Fit HMSC model",
    name = "mod_hmsc",
    command = fit_hmsc_model(
      data_community = data_community_to_fit,
      data_abiotic = data_abiotic_to_fit
    ),
    format = "qs"
  )
)

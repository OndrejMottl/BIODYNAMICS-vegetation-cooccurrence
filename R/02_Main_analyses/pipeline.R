#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
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
  seed = get_active_config("seed"),
  format = "qs",
  error = "null"
)

# set the number of cores to use
n_cores <- 10

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

# This section is basically a very complicated target factory.

# This is done to reduce code duplication (several parts of pipe chain repeats).
#  And mainly to use the `tar_combine` function to combine the results.

# I am aware that this is not the most elegant solution, but it works.

#--------------------------------------------------#
## Configurations -----
#--------------------------------------------------#
list_target_config <-
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
      description = "Configuration for data processing",
      name = "config.data_processing",
      command = list(
        time_step = config.time_step,
        number_of_taxa = config.number_of_taxa,
        min_distance_of_gpp_knots = config.min_distance_of_gpp_knots
      )
    ),
    #--------------------------------------------------#
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
      description = "Configuration for model fitting",
      name = "config.model_fitting",
      command = list(
        samples = config.n_samples,
        thin = config.n_thin,
        transient = config.n_transient,
        samples_verbose = config.samples_verbose,
        cross_validation_folds = config.cross_validation_folds
      )
    )
  )


#--------------------------------------------------#
## VegVault data -----
#--------------------------------------------------#

list_target_vegvault_data <-
  list(
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
      )
    ),
    targets::tar_target(
      description = "Get coordinates of the VegVault data",
      name = "data_coords",
      command = get_coords(data_vegvault_extracted)
    )
  )


#--------------------------------------------------#
## Community data -----
#--------------------------------------------------#
list_target_community_data <-
  list(
    targets::tar_target(
      description = "Extract community data",
      name = "data_community",
      command = get_community_data(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Get community data into long-format",
      name = "data_community_long",
      command = make_community_data_long(data_community)
    ),
    targets::tar_target(
      description = "Get sample ages",
      name = "data_sample_ages",
      command = get_sample_ages(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Add sample ages to community data",
      name = "data_community_long_ages",
      command = add_age_to_samples(data_community_long, data_sample_ages)
    ),
    targets::tar_target(
      description = "Interpolate community data to specific time step",
      name = "data_community_interpolated",
      command = interpolate_community_data(
        data = data_community_long_ages,
        timestep = config.data_processing$time_step
      )
    ),
    targets::tar_target(
      description = "Select number of taxa to include",
      name = "data_community_subset",
      command = select_n_taxa(
        data = data_community_interpolated,
        n_taxa = config.data_processing$number_of_taxa
      )
    ),
    targets::tar_target(
      description = "Prepare community data for fitting",
      name = "data_community_to_fit",
      command = prepare_data_for_fit(
        data = data_community_subset,
        type = "community"
      )
    )
  )


#--------------------------------------------------#
## Abiotic data -----
#--------------------------------------------------#
list_target_abiotic_data <-
  list(
    targets::tar_target(
      description = "Extract abiotic data",
      name = "data_abiotic",
      command = get_abiotic_data(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = "Add sample ages to abiotic data",
      name = "data_abiotic_ages",
      command = add_age_to_samples(data_abiotic, data_sample_ages) %>%
        dplyr::select(-sample_name)
    ),
    targets::tar_target(
      description = "Interpolate abiotic data to specific time step",
      name = "data_abiotic_interpolated",
      command = interpolate_data(
        data = data_abiotic_ages,
        value_var = "abiotic_value",
        by = c("dataset_name", "abiotic_variable_name"),
        timestep = config.data_processing$time_step
      )
    ),
    targets::tar_target(
      description = "Prepare abiotic data for fitting",
      name = "data_abiotic_to_fit",
      command = prepare_data_for_fit(
        data = data_abiotic_interpolated,
        type = "abiotic"
      )
    )
  )


#--------------------------------------------------#
## Model fitting -----
#--------------------------------------------------#

# get the model formulae to use
data_to_map_formula <-
  tibble::tibble(
    model_formula = c("~ 1", "~ ."),
    formula_name = c("null", "full")
  )

#----------------------------------------#
### basic pipe to fit and evaluate the model
#----------------------------------------#

list_target_fit_and_evaluate <-
  list(
    targets::tar_target(
      description = "make HMSC model",
      name = "mod_hmsc",
      command = make_hmsc_model(
        data_to_fit = data_to_fit,
        sel_formula = model_formula,
        random_structure = mod_random_structure,
        error_family = "binomial"
      )
    ),
    targets::tar_target(
      description = "Fit the HMSC model",
      name = "mod_hmsc_fitted",
      command = fit_hmsc_model(
        mod_hmsc = mod_hmsc,
        n_chains = n_cores,
        n_parallel = n_cores,
        n_samples = config.model_fitting$samples,
        n_thin = config.model_fitting$thin,
        n_transient = config.model_fitting$transient,
        n_samples_verbose = config.model_fitting$samples_verbose
      )
    ),
    targets::tar_target(
      description = "Make the partition for cross-validation",
      name = "mod_hmsc_partition",
      command = Hmsc::createPartition(
        hM = mod_hmsc_fitted,
        nfolds = config.model_fitting$cross_validation_folds,
        column = "dataset_name"
      )
    ),
    targets::tar_target(
      description = "Predict the model",
      name = "mod_hmsc_pred",
      command = Hmsc::computePredictedValues(
        hM = mod_hmsc_fitted,
        nChains = length(mod_hmsc_fitted$postList),
        nParallel = length(mod_hmsc_fitted$postList),
        partition = mod_hmsc_partition,
      )
    ),
    targets::tar_target(
      description = "Evaluate the model",
      name = "mod_hmsc_eval",
      command = add_model_evaluation(
        mod_fitted = mod_hmsc_fitted,
        data_pred = mod_hmsc_pred
      )
    )
  )


list_target_model_full <-
  tarchetypes::tar_map(
    values = data_to_map_formula,
    descriptions = "formula_name",
    targets::tar_target(
      description = "Check and prepare the data for fitting",
      name = "data_to_fit",
      command = check_and_prepare_data_for_fit(
        data_community = data_community_to_fit,
        data_abiotic = data_abiotic_to_fit,
        data_coords = data_coords
      )
    ),
    targets::tar_target(
      description = "Make a random structure for the HMSC model",
      name = "mod_random_structure",
      command = get_random_structure_for_model(
        data = data_to_fit,
        type = c("age", "space"),
        min_knots_distance = config.data_processing$min_distance_of_gpp_knots
      )
    ),
    list_target_fit_and_evaluate
  )
list_target_models_species_associations <-
  list(
    targets::tar_target(
      description = "Get species associations",
      name = "species_associations",
      command = get_species_association(mod_hmsc_fitted_selected)
    ),
    targets::tar_target(
      description = "Get number of significant associations",
      name = "number_of_significant_associations",
      command = get_significant_associations(
        species_associations,
        alpha = 0.05
      )
    )
  )

list_target_models_full_associations <-
  list(
    list_target_model_full,
    tarchetypes::tar_combine(
      name = "mod_hmsc_fitted_combined",
      list_target_model_full[["mod_hmsc_eval"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = "Select either null or full model based on fit",
      name = "mod_hmsc_fitted_selected",
      command = get_better_model_based_on_fit(mod_hmsc_fitted_combined)
    ),
    list_target_models_species_associations
  )


#----------------------------------------#
### Pipe factory to have a model for each age
#----------------------------------------#

# get the list of expected ages
data_to_map_age <-
  tibble::tibble(
    age = seq(
      from = min(get_active_config(c("vegvault_data", "age_lim"))),
      to = max(get_active_config(c("vegvault_data", "age_lim"))),
      by = get_active_config(c("data_processing", "time_step"))
    ),
    age_name = paste0("timeslice_", age)
  )

list_target_models_by_age <-
  # make a branch for each model type (null, full)
  tarchetypes::tar_map(
    values = data_to_map_formula,
    descriptions = "formula_name",
    targets::tar_target(
      description = "Check and prepare the data for fitting",
      name = "data_to_fit",
      command = check_and_prepare_data_for_fit(
        data_community = data_community_to_fit,
        data_abiotic = data_abiotic_to_fit,
        data_coords = data_coords,
        subset_age = age
      )
    ),
    targets::tar_target(
      description = "Make a random structure for the HMSC model",
      name = "mod_random_structure",
      command = get_random_structure_for_model(
        data = data_to_fit,
        type = "space",
        min_knots_distance = config.data_processing$min_distance_of_gpp_knots
      )
    ),
    list_target_fit_and_evaluate
  )

list_target_models_by_age_with_summary <-
  list(
    list_target_models_by_age,
    tarchetypes::tar_combine(
      name = "mod_hmsc_fitted_combined",
      list_target_models_by_age[["mod_hmsc_eval"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = "Select either null or full model based on fit",
      name = "mod_hmsc_fitted_selected",
      command = get_better_model_based_on_fit(mod_hmsc_fitted_combined)
    ),
    list_target_models_species_associations
  )

list_models_by_age <-
  # make a branch for each age
  tarchetypes::tar_map(
    values = data_to_map_age,
    descriptions = "age_name",
    list_target_models_by_age_with_summary
  )

list(
  list_target_config,
  list_target_vegvault_data,
  list_target_community_data,
  list_target_abiotic_data,
  list_target_models_full_associations,
  list_models_by_age,
  tarchetypes::tar_combine(
    name = "species_associations_by_age_merged",
    list_models_by_age[["number_of_significant_associations"]],
    command = list(!!!.x)
  ),
  targets::tar_target(
    description = "Table of significant associations by age",
    name = "data_species_associations_by_age",
    command = species_associations_by_age_merged %>%
      purrr::map("dataset_name") %>%
      purrr::map("proportion_significant") %>%
      unlist() %>%
      purrr::set_names(
        nm = names(.) %>%
          stringr::str_extract(., "_timeslice_\\d+") %>%
          stringr::str_remove(., "_timeslice_")
      ) %>%
      as.data.frame() %>%
      purrr::set_names("prop_sign_assoc") %>%
      tibble::rownames_to_column("age") %>%
      dplyr::mutate(
        age = as.numeric(age)
      )
  ),
  targets::tar_target(
    description = "Table of species associations total",
    name = "data_species_associations_total",
    command = number_of_significant_associations %>%
      purrr::map("proportion_significant") %>%
      unlist() %>%
      purrr::set_names(
        nm = names(.)
      ) %>%
      as.data.frame() %>%
      purrr::set_names("n_sign_assoc") %>%
      tibble::rownames_to_column("type")
  ),
  targets::tar_target(
    description = "Plot of significant associations by age",
    name = "plot_species_associations_by_age",
    command = ggplot2::ggplot() +
      ggplot2::geom_line(
        data = data_species_associations_by_age,
        mapping = ggplot2::aes(
          x = age,
          y = prop_sign_assoc
        )
      ) +
      ggplot2::geom_point(
        data = data_species_associations_by_age,
        mapping = ggplot2::aes(
          x = age,
          y = prop_sign_assoc
        )
      ) +
      ggplot2::geom_hline(
        data = data_species_associations_total,
        mapping = ggplot2::aes(
          yintercept = n_sign_assoc,
          col = type
        ),
        linetype = "dashed"
      ) +
      ggplot2::coord_cartesian(
        ylim = c(0, 1),
      ) +
      ggplot2::scale_x_continuous(
        trans = "reverse"
      ) +
      ggplot2::labs(
        title = "Proportion of significant associations by age",
        subtitle = paste("project:", Sys.getenv("R_CONFIG_ACTIVE")),
        x = "Age (cal yr BP)",
        y = "Proportion of significant associations"
      )
  )
)

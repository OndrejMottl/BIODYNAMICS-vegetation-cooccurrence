#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Model fitting
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up Model fitting


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

# get the model formulae to use
data_to_map_formula <-
  tibble::tibble(
    model_formula = c("~ 1", "~ ."),
    formula_name = c("null", "full")
  )

# list of targets to fit and evaluate the model
pipe_target_fit_and_evaluate <-
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
        n_chains = config.model_fitting$n_cores,
        n_parallel = config.model_fitting$n_cores,
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

pipe_target_model_full <-
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
    pipe_target_fit_and_evaluate
  )
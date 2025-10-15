#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Simple model fitting
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up a simple model fitting


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

pipe_segment_model_fit <-
  list(
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

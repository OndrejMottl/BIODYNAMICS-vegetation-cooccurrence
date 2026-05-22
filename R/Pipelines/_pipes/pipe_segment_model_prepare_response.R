#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       {targets} pipe: Model response preparation
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Prepares the community response and scaled abiotic predictors
#   used by model fitting.


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

pipe_segment_model_prepare_response <-
  list(
    targets::tar_target(
      description = "Scale abiotic predictors; capture attributes",
      name = "data_abiotic_scaled_list",
      command = scale_abiotic_for_fit(
        data_abiotic_wide = data_abiotic_wide
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Binarize or pass through community matrix based on ",
        "the configured error family"
      ),
      name = "data_community_prepared",
      command = {
        if (
          config_model_fitting$error_family == "binomial"
        ) {
          binarize_community_data(
            data_community_matrix = data_community_model_matrix
          )
        } else {
          data_community_model_matrix
        }
      }
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Remove constant taxa from community matrix ",
        "(zero standard deviation)"
      ),
      name = "data_community_filtered",
      command = filter_constant_taxa(
        data_community_matrix = data_community_prepared
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Stop pipeline if fewer than min_n_taxa taxa remain ",
        "after filtering"
      ),
      name = "data_community_n_taxa_checked",
      command = filter_community_by_n_taxa(
        data_community_matrix = data_community_filtered,
        min_n_taxa = config_data_processing$min_n_taxa
      )
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             {targets} pipe: Model data assembly
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Assembles prepared response, abiotic predictors, and optional
#   spatial predictors into the model input list.


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

pipe_segment_model_assemble <-
  list(
    targets::tar_target(
      description = "Validate and assemble data list for fitting",
      name = "data_model_input",
      command = assemble_data_to_fit(
        data_community_filtered = data_community_n_taxa_checked,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    )
  )

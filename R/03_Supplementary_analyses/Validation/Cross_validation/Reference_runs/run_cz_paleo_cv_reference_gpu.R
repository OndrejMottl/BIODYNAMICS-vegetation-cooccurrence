#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Run CZ paleo real CV reference on GPU
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for the GPU comparison reference.
# The separate profile and store preserve the historical CPU evidence.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

base::suppressWarnings(
  source(
    here::here("R/___setup_project___.R")
  )
)


#----------------------------------------------------------#
# 1. Paleo CZ real CV GPU reference -----
#----------------------------------------------------------#

base::Sys.setenv(
  R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference_gpu"
)

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_core.R",
  fresh_run = TRUE,
  prebuild_interpolation = TRUE,
  vec_allowed_profile_roles = "reference",
  vec_allowed_profile_statuses = "frozen"
)

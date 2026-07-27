#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Run paleo local scientific CV reference on GPU
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for the larger European paleo CV reference.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

base::suppressWarnings(
  base::source(
    here::here("R/___setup_project___.R")
  )
)


#----------------------------------------------------------#
# 1. Paleo local scientific CV reference -----
#----------------------------------------------------------#

base::Sys.setenv(
  R_CONFIG_ACTIVE =
    "project_paleo_local_cv_scientific_reference_gpu"
)

run_pipeline(
  sel_script =
    "R/Pipelines/pipeline_paleo_local_cv_scientific_reference.R",
  fresh_run = TRUE,
  prebuild_interpolation = FALSE,
  vec_allowed_profile_roles = "reference",
  vec_allowed_profile_statuses = "frozen"
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Run CZ paleo real CV reference
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for the dedicated Czechia paleo CV reference.
# The separate profile and store preserve the fast mandatory CZ test.


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
# 1. Paleo CZ real CV reference -----
#----------------------------------------------------------#

base::Sys.setenv(
  R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference"
)

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_core.R",
  fresh_run = TRUE,
  prebuild_interpolation = TRUE,
  vec_allowed_profile_roles = "reference",
  vec_allowed_profile_statuses = "frozen"
)

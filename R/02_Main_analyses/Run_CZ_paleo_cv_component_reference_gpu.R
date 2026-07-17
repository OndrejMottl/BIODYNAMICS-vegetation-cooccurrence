#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Run CZ paleo CV component reference on GPU
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone runner for the isolated predictor-component comparison.


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
# 1. CZ paleo predictor-component reference -----
#----------------------------------------------------------#

base::Sys.setenv(
  R_CONFIG_ACTIVE = "project_cz_paleo_cv_component_reference_gpu"
)

run_pipeline(
  sel_script =
    "R/Pipelines/pipeline_cz_paleo_cv_component_reference.R",
  fresh_run = TRUE,
  prebuild_interpolation = FALSE
)

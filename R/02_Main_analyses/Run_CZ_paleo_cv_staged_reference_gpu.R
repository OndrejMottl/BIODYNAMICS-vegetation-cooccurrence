#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Run staged CZ paleo real CV reference on GPU
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Paired staged-search runner for the exhaustive GPU reference.


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
# 1. Build staged tuning rounds -----
#----------------------------------------------------------#

base::Sys.setenv(
  R_CONFIG_ACTIVE = "project_cz_paleo_cv_staged_reference_gpu"
)

run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_core.R",
  tuning_target_names = "data_sjsdm_tuning_summary",
  prebuild_interpolation = TRUE,
  fresh_run = TRUE,
  tuning_strategy = load_active_config_value(
    base::c("model_fitting", "cross_validation", "tuning_strategy")
  ),
  n_rounds = base::length(
    load_active_config_value(
      base::c(
        "model_fitting",
        "cross_validation",
        "staged_search",
        "repeat_order"
      )
    )
  )
)


#----------------------------------------------------------#
# 2. Complete the public core pipeline -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_core.R",
  prebuild_interpolation = FALSE
)

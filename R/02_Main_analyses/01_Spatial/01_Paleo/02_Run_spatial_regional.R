#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Run spatial scale pipeline: regional
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Iterates over all regional spatial units defined in
#   Data/Input/spatial_grid.csv and runs pipeline_paleo_spatial_resolution.R
#   for each one in sequence (genus + family + functional_type).
# Each unit gets an isolated targets store at:
#   Data/targets/paleo_spatial_regional/{scale_id}/
#   pipeline_paleo_spatial_resolution/


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Set active configuration -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_regional")


#----------------------------------------------------------#
# 2. Load spatial units -----
#----------------------------------------------------------#

vec_scale_ids <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(scale == "regional") |>
  dplyr::pull(scale_id)

vec_tuning_target_names <-
  stringr::str_c(
    "data_sjsdm_tuning_summary_",
    base::c("genus", "family", "functional_type")
  )


#----------------------------------------------------------#
# 3. Build unit tuning summaries -----
#----------------------------------------------------------#

# This stage is fail-fast because tier selection requires every unit summary.
run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
  tuning_target_names = vec_tuning_target_names,
  unit_store_suffixes = vec_scale_ids,
  prebuild_interpolation = TRUE,
  tuning_strategy = get_active_config(
    base::c("model_fitting", "cross_validation", "tuning_strategy")
  ),
  n_rounds = base::length(
    get_active_config(
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
# 4. Complete resolution pipeline for each spatial unit -----
#----------------------------------------------------------#

# Post-selection runs continue and retain one status row per spatial unit.
tictoc::tic(
  "Running resolution pipelines (genus + family + FT) for all regional units"
)
data_pipeline_status <-
  run_pipeline_units_with_status(
    scale_ids = vec_scale_ids,
    sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
    prebuild_interpolation = FALSE
  )
tictoc::toc()

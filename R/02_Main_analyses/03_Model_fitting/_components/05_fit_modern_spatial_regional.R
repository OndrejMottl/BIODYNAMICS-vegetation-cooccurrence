#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Fit modern spatial regional models
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Iterates over all regional spatial units and runs
#   pipeline_modern_spatial_resolution.R for each unit.
# Workflow contract:
#   Requires completed preparation from stage 01 and calibrated CV budgets
#   from stage 02. It runs tuning and final fitting only and reuses cached
#   preparation. Rerun stage 03 after interruption to resume completed work.

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

Sys.setenv(R_CONFIG_ACTIVE = "project_modern_spatial_regional")


#----------------------------------------------------------#
# 2. Load spatial units -----
#----------------------------------------------------------#

vec_scale_ids <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(
    .data[["scale"]] == "regional"
  ) |>
  dplyr::pull(scale_id)

vec_tuning_target_names <-
  stringr::str_c(
    "list_sjsdm_cv_tuning_artifact_",
    base::c("genus", "family", "ft_modern")
  )

# Recheck only failed preparation roots, never their CV/model descendants.
# Resolution-specific data limits must not discard other viable models.
data_preparation_plan <-
  run_sjsdm_unit_fitting_preflight(
    unit_pipeline = "R/Pipelines/pipeline_modern_spatial_resolution.R",
    target_store = load_active_config_value("target_store"),
    scale_ids = vec_scale_ids,
    resolution_ids = base::c("genus", "family", "ft_modern")
  )
list_unit_tuning_targets <-
  build_sjsdm_unit_fitting_targets(data_preparation_plan,
    target_names = vec_tuning_target_names)
data_pipeline_manifest <-
  targets::tar_manifest(
    script = "R/Pipelines/pipeline_modern_spatial_resolution.R",
    fields = "name", callr_function = NULL
  )
list_unit_fitting_targets <-
  build_sjsdm_unit_fitting_targets(data_preparation_plan,
    target_names = data_pipeline_manifest[["name"]])
path_status <-
  here::here("Data/Temp/Main_analysis_execution/03_model_fitting")
fs::dir_create(path_status)
run_id <-
  base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
readr::write_csv(data_preparation_plan,
  fs::path(path_status, stringr::str_glue(
    "modern_regional_preparation_plan_{run_id}.csv")))

#----------------------------------------------------------#
# 3. Build unit tuning summaries -----
#----------------------------------------------------------#

# Failed units are logged and excluded from tier selection.
run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_modern_spatial_resolution.R",
  tuning_target_names = vec_tuning_target_names,
  unit_store_suffixes = vec_scale_ids,
  unit_target_names = list_unit_tuning_targets,
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
# 4. Complete resolution pipeline for each spatial unit -----
#----------------------------------------------------------#

# Post-selection runs continue and retain one status row per spatial unit.
tictoc::tic(
  "Running modern resolution pipelines for all regional units"
)
data_pipeline_status <-
  run_pipeline_units_with_status(
    scale_ids = vec_scale_ids,
    sel_script = "R/Pipelines/pipeline_modern_spatial_resolution.R",
    prebuild_interpolation = FALSE,
    unit_target_names = list_unit_fitting_targets
  )
tictoc::toc()
file_status <-
  fs::path(path_status,
    stringr::str_glue("modern_regional_unit_status_{run_id}.csv"))
readr::write_csv(data_pipeline_status, file_status)
base::message("Regional unit status: ", file_status)
if (
  base::any(data_pipeline_status[["pipeline_status"]] == "error")
) {
  base::print(data_pipeline_status)
  cli::cli_abort(
    "Regional fitting has unexpected unit failures; see the component log."
  )
}

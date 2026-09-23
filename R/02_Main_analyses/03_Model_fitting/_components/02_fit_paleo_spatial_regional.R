#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Fit paleo spatial regional models
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

file_preparation_inventory <-
  here::here(
    "Documentation/Reports/Model_calibration/sjsdm_cv_fit_budget",
    "calibration_unit_inventory.csv"
  )
if (
  !base::file.exists(file_preparation_inventory)
) {
  cli::cli_abort(
    base::c(
      "Regional fitting requires stage 02 preparation evidence.",
      "i" = stringr::str_c(
        "Run R/02_Main_analyses/01_Preparation/",
        "01_run_preparation.R, then ",
        "R/02_Main_analyses/02_Model_calibration/",
        "01_run_model_calibration.R."
      )
    )
  )
}
data_preparation_inventory <-
  readr::read_csv(
    file_preparation_inventory,
    show_col_types = FALSE
  )
data_unit_fitting_plan <-
  build_sjsdm_unit_fitting_plan(
    data_preparation_inventory = data_preparation_inventory,
    analysis_id = "paleo_spatial",
    tier_id = "regional",
    scale_ids = vec_scale_ids,
    resolution_ids = base::c(
      "genus",
      "family",
      "functional_type"
    )
  )
vec_expected_infeasible_scale_ids <-
  data_unit_fitting_plan |>
  dplyr::filter(
    .data[["fitting_status"]] == "expected_infeasible"
  ) |>
  dplyr::pull("scale_id")
vec_fit_scale_ids <-
  vec_scale_ids[
    !vec_scale_ids %in% vec_expected_infeasible_scale_ids
  ]
base::message(
  stringr::str_glue(
    "Regional fitting: {base::length(vec_fit_scale_ids)} eligible, ",
    "{base::length(vec_expected_infeasible_scale_ids)} ",
    "expected-infeasible units."
  )
)

vec_tuning_target_names <-
  stringr::str_c(
    "list_sjsdm_cv_tuning_artifact_",
    base::c("genus", "family", "functional_type")
  )

#----------------------------------------------------------#
# 3. Build unit tuning summaries -----
#----------------------------------------------------------#

# Unit target failures are logged and skipped. Tier selection uses only stores
# that completed the current tuning round.
run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
  tuning_target_names = vec_tuning_target_names,
  unit_store_suffixes = vec_fit_scale_ids,
  prebuild_interpolation = TRUE,
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
  "Running resolution pipelines (genus + family + FT) for regional units"
)
data_pipeline_status <-
  run_pipeline_units_with_status(
    scale_ids = vec_scale_ids,
    sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
    prebuild_interpolation = FALSE,
    expected_infeasible_scale_ids =
      vec_expected_infeasible_scale_ids
  )
tictoc::toc()

data_pipeline_status_with_preparation <-
  data_pipeline_status |>
  dplyr::left_join(
    data_unit_fitting_plan |>
      dplyr::select(
        .data[["scale_id"]],
        .data[["preparation_reason_code"]]
      ),
    by = dplyr::join_by(scale_id)
  )
path_status <-
  here::here("Data/Temp/Main_analysis_execution/03_model_fitting")
fs::dir_create(path_status)
file_status <-
  fs::path(
    path_status,
    stringr::str_glue(
      "paleo_regional_unit_status_",
      "{base::format(base::Sys.time(), '%Y%m%d_%H%M%S')}.csv"
    )
  )
readr::write_csv(data_pipeline_status_with_preparation, file_status)
base::message("Regional unit status: ", file_status)
if (
  base::any(data_pipeline_status[["pipeline_status"]] == "error")
) {
  cli::cli_abort(
    "Regional fitting has unexpected unit failures; see {.file {file_status}}."
  )
}

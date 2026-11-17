#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Fit paleo temporal Europe models
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the time-slice pipeline for the pan-European region.
# Uses project_paleo_temporal_europe configuration (lon -10–40°E, lat 35–70°N,
#   0–20 kyr BP, 500-yr steps).
# Target store: Data/targets/paleo_temporal_europe/pipeline_paleo_temporal/
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

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_europe")


#----------------------------------------------------------#
# 2. Load time-slice targets -----
#----------------------------------------------------------#

# All slices in the window (temporal_slices.age_window; issue #181); slices
#   listed in temporal_slices.excluded_ages are not modelled.
data_slices_window <-
  load_temporal_slice_ages(flag_modelled_only = FALSE)

data_slices <-
  data_slices_window |>
  dplyr::filter(.data[["flag_modelled"]])

vec_tuning_target_names <-
  stringr::str_c(
    "list_sjsdm_cv_tuning_artifact_",
    dplyr::pull(data_slices, "age_name")
  )


#----------------------------------------------------------#
# 3. Build tuning summaries and shared tier artifact -----
#----------------------------------------------------------#

# Slices that are expected to be infeasible (for example too few samples)
#   are classified per slice and left out of tuning; other slices continue.
run_sjsdm_tuning_sequence(
  unit_pipeline = "R/Pipelines/pipeline_paleo_temporal.R",
  tuning_target_names = vec_tuning_target_names,
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
  ),
  slice_ids = dplyr::pull(data_slices, "age_name")
)


#----------------------------------------------------------#
# 4. Complete temporal pipeline -----
#----------------------------------------------------------#

# Expected infeasible slices raise a classed condition and the per-slice
#   status below decides whether the run is acceptable. An unexplained
#   pipeline failure always stops the runner after the status is written.
condition_pipeline <-
  base::tryCatch(
    expr = {
      run_pipeline(
        sel_script = "R/Pipelines/pipeline_paleo_temporal.R",
        prebuild_interpolation = FALSE
      )
      NULL
    },
    sjsdm_unit_expected_infeasible = function(condition) condition,
    sjsdm_unit_pipeline_error = function(condition) condition
  )


#----------------------------------------------------------#
# 5. Record per-slice status -----
#----------------------------------------------------------#

data_slice_status <-
  classify_sjsdm_timeslice_status(
    data_target_errors = load_targets_store_metadata(
      store_path = resolve_pipeline_store_path(
        pipeline_script = "R/Pipelines/pipeline_paleo_temporal.R"
      ),
      fields = base::c("name", "error")
    ),
    vec_slice_ids = dplyr::pull(data_slices_window, "age_name"),
    vec_excluded_slice_ids = data_slices_window |>
      dplyr::filter(!.data[["flag_modelled"]]) |>
      dplyr::pull("age_name"),
    terminal_target_prefix = "list_jsdm_variance_partition_"
  ) |>
  dplyr::mutate(
    profile_id = base::Sys.getenv("R_CONFIG_ACTIVE"),
    pipeline_condition = if (
      base::is.null(condition_pipeline)
    ) {
      NA_character_
    } else {
      base::conditionMessage(condition_pipeline)
    },
    .before = 1L
  )

path_status <-
  here::here("Data/Temp/Main_analysis_execution/03_model_fitting")
fs::dir_create(path_status)
file_status <-
  fs::path(
    path_status,
    stringr::str_glue(
      "paleo_temporal_europe_slice_status_",
      "{base::format(base::Sys.time(), '%Y%m%d_%H%M%S')}.csv"
    )
  )
readr::write_csv(data_slice_status, file_status)
base::message("Temporal slice status: ", file_status)

if (
  base::inherits(condition_pipeline, "sjsdm_unit_pipeline_error") ||
    base::any(
      data_slice_status[["status"]] %in%
        base::c("unexpected_error", "not_built")
    )
) {
  cli::cli_abort(
    "Temporal fitting has failed or unbuilt slices; see {.file {file_status}}."
  )
}

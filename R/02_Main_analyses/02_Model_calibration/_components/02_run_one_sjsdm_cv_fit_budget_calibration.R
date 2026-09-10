#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Calibrate one sjSDM CV fit budget
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Run the registered calibration ladder for one representative using only
#   cached prepared folds selected by the calibration inventory.
# Workflow contract:
#   Invoked by the stage 02 master, which supplies registered identifiers from
#   calibration_representatives.csv. Users should not run this component.
#   Accepted results are restart-safe under Data/Temp/Sjsdm_cv_calibration/;
#   set SJSMD_CALIBRATION_FORCE=true only to replace an accepted result.
#   Failure to pass every convergence and stability gate is fatal.

#----------------------------------------------------------#
# 0. Read invocation -----
#----------------------------------------------------------#

profile_id <-
  base::Sys.getenv("SJSMD_CALIBRATION_PROFILE")
scale_id <-
  base::Sys.getenv("SJSMD_CALIBRATION_SCALE_ID")
resolution_id <-
  base::Sys.getenv("SJSMD_CALIBRATION_RESOLUTION")
flag_force <-
  base::identical(
    base::tolower(base::Sys.getenv("SJSMD_CALIBRATION_FORCE")),
    "true"
  )

if (
  base::any(base::nchar(base::c(profile_id, scale_id, resolution_id)) == 0L)
) {
  base::stop(
    "Run R/02_Main_analyses/02_Model_calibration/",
    "01_run_model_calibration.R instead of this internal component."
  )
}

base::Sys.setenv(R_CONFIG_ACTIVE = profile_id)
library(here)
source(here::here("R/___setup_project___.R"))

#----------------------------------------------------------#
# 1. Resolve registered cached inputs -----
#----------------------------------------------------------#

flag_spatial <-
  stringr::str_detect(profile_id, "_spatial_")
pipeline_id <-
  if (
    flag_spatial
  ) {
    stringr::str_c(
      "pipeline_",
      stringr::str_extract(profile_id, "(paleo|modern)_spatial"),
      "_resolution"
    )
  } else {
    "pipeline_paleo_temporal"
  }
path_store <-
  if (
    flag_spatial
  ) {
    here::here(load_active_config_value("target_store"), scale_id, pipeline_id)
  } else {
    here::here(load_active_config_value("target_store"), pipeline_id)
  }
file_representatives <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "calibration_representatives.csv"
  )
assertthat::assert_that(
  base::file.exists(file_representatives),
  msg = paste(
    "Calibration runner 02 cannot start because",
    "calibration_representatives.csv is missing. First finish all",
    "stage 01 preparation, then run the stage 02 master."
  )
)
data_representative <-
  readr::read_csv(file_representatives, show_col_types = FALSE) |>
  dplyr::mutate(
    registered_profile_id = dplyr::if_else(
      .data[["is_temporal"]],
      stringr::str_c(
        "project_paleo_temporal_",
        .data[["continent_id"]]
      ),
      stringr::str_c(
        "project_",
        .data[["analysis_id"]],
        "_",
        .data[["tier_id"]]
      )
    )
  ) |>
  dplyr::filter(
    .data[["registered_profile_id"]] == .env[["profile_id"]],
    .data[["scale_id"]] == .env[["scale_id"]],
    .data[["resolution_id"]] == .env[["resolution_id"]]
  )
assertthat::assert_that(
  base::nrow(data_representative) == 1L,
  !base::is.na(data_representative[["target_suffix"]][[1L]]),
  msg = paste(
    "The requested representative is not registered with a cached target.",
    "Check the three SJSMD_CALIBRATION_* values against",
    "calibration_representatives.csv. If the row or target suffix is",
    "missing, rerun stage 01 preparation and then stage 02 calibration."
  )
)
target_suffix <-
  stringr::str_c("_", data_representative[["target_suffix"]][[1L]])

path_output <-
  here::here(
    "Data",
    "Temp",
    "Sjsdm_cv_calibration",
    profile_id,
    scale_id,
    resolution_id
  )
path_report <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    profile_id,
    scale_id,
    resolution_id
  )
fs::dir_create(path_output)
fs::dir_create(path_report)
file_result <-
  fs::path(path_output, "calibration_result.qs")

if (
  base::file.exists(file_result) && !flag_force
) {
  list_existing <-
    qs2::qs_read(file_result)
  if (
    base::identical(list_existing[["calibration_status"]], "accepted")
  ) {
    cli::cli_inform("Reusing the completed accepted calibration result.")
    base::quit(save = "no", status = 0L)
  }
}

#----------------------------------------------------------#
# 2. Load prepared folds and model inputs -----
#----------------------------------------------------------#

vec_required_target_names <-
  stringr::str_c(
    base::c(
      "list_sjsdm_prepared_tuning_folds",
      "data_sjsdm_regularization_candidates",
      "formula_jsdm_environment",
      "config_model_fitting"
    ),
    target_suffix
  )
data_store_meta <-
  base::tryCatch(
    targets::tar_meta(store = path_store),
    error = function(error_condition) {
      tibble::tibble(name = base::character())
    }
  )
vec_missing_target_names <-
  base::setdiff(vec_required_target_names, data_store_meta[["name"]])
if (
  base::length(vec_missing_target_names) > 0L
) {
  cli::cli_abort(
    base::c(
      "Calibration runner 02 cannot find its prepared production inputs.",
      "x" = stringr::str_glue(
        "Missing from '{path_store}': ",
        "{stringr::str_c(vec_missing_target_names, collapse = ', ')}."
      ),
      "1" = paste(
        "Rerun stage 01 preparation for this profile and unit."
      ),
      "2" = paste(
        "After preparation succeeds, rerun calibration runner 01 and then",
        "invoke runner 02 using the registered identifiers."
      )
    )
  )
}

list_prepared_folds <-
  targets::tar_read_raw(
    name = stringr::str_c(
      "list_sjsdm_prepared_tuning_folds",
      target_suffix
    ),
    store = path_store
  )
data_candidates <-
  targets::tar_read_raw(
    name = stringr::str_c(
      "data_sjsdm_regularization_candidates",
      target_suffix
    ),
    store = path_store
  )
formula_jsdm_environment <-
  targets::tar_read_raw(
    name = stringr::str_c("formula_jsdm_environment", target_suffix),
    store = path_store
  )
config_model_fitting <-
  targets::tar_read_raw(
    name = stringr::str_c("config_model_fitting", target_suffix),
    store = path_store
  )

config_fit_budget <-
  base::list(
    n_iter_initial = 500L,
    n_iter_max = 500L,
    n_sampling = 200L,
    n_step_size = NULL,
    n_early_stopping = NULL
  )
config_sjsdm_cv_fitting <-
  build_sjsdm_cross_validation_fitting_config(
    config_model_fitting = config_model_fitting,
    config_fit_budget = config_fit_budget
  )

#----------------------------------------------------------#
# 3. Run the restart-safe calibration benchmark -----
#----------------------------------------------------------#

started_at <-
  base::Sys.time()
list_result <-
  run_sjsdm_cv_calibration_benchmark(
    data_candidates = data_candidates,
    list_prepared_folds = list_prepared_folds,
    sel_abiotic_formula = formula_jsdm_environment,
    config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
    device = purrr::chuck(
      config_sjsdm_cv_fitting,
      "cross_validation",
      "fit_device"
    )
  )
finished_at <-
  base::Sys.time()

list_result[["run_provenance"]] <-
  tibble::tibble(
    commit = system2("git", base::c("rev-parse", "HEAD"), stdout = TRUE),
    profile_id = profile_id,
    scale_id = scale_id,
    resolution_id = resolution_id,
    target_suffix = target_suffix,
    store_path = path_store,
    started_at = started_at,
    finished_at = finished_at,
    elapsed_hours = base::as.numeric(
      base::difftime(finished_at, started_at, units = "hours")
    ),
    calibration_status = list_result[["calibration_status"]]
  )

qs2::qs_save(list_result, file_result)

#----------------------------------------------------------#
# 4. Publish evidence for review -----
#----------------------------------------------------------#

readr::write_csv(
  list_result[["data_accepted_budget"]],
  fs::path(path_report, "accepted_budget.csv"),
  na = "NA"
)
readr::write_csv(
  list_result[["data_benchmark"]],
  fs::path(path_report, "benchmark_evidence.csv"),
  na = "NA"
)
readr::write_csv(
  list_result[["data_fit_attempts"]],
  fs::path(path_report, "fit_attempts.csv"),
  na = "NA"
)
readr::write_csv(
  list_result[["run_provenance"]],
  fs::path(path_report, "run_provenance.csv"),
  na = "NA"
)

if (
  list_result[["calibration_status"]] != "accepted"
) {
  cli::cli_abort("No CV budget passed every calibration gate.")
}

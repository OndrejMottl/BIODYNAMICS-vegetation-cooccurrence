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
calibration_contract_version <-
  "sjsdm_cv_adaptive_calibration_v3"
legacy_calibration_contract_version <-
  "sjsdm_cv_adaptive_calibration_v2"
repeat_confirmation_loss_tolerance <-
  0.02

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

list_existing <-
  if (
    base::file.exists(file_result) && !flag_force
  ) {
    qs2::qs_read(file_result)
  } else {
    NULL
  }

#----------------------------------------------------------#
# 2. Load prepared folds and model inputs -----
#----------------------------------------------------------#

target_prepared_folds <-
  stringr::str_c(
    "list_sjsdm_prepared_tuning_folds",
    target_suffix
  )
target_model_fitting_config <-
  if (
    flag_spatial
  ) {
    stringr::str_c("config_model_fitting", target_suffix)
  } else {
    "config_model_fitting"
  }
vec_required_target_names <-
  base::c(target_prepared_folds, target_model_fitting_config)
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
    name = target_prepared_folds,
    store = path_store
  )
config_model_fitting <-
  targets::tar_read_raw(
    name = target_model_fitting_config,
    store = path_store
  )

# Preparation intentionally persists the expensive fold cache and its fitting
# configuration, while disposable formula and candidate targets may be pruned.
# Rebuild both with the same production functions and configuration values.
config_regularization <-
  purrr::chuck(
    config_model_fitting,
    "cross_validation",
    "regularization"
  )
data_candidates <-
  build_sjsdm_regularization_candidates(
    alpha_cov = purrr::chuck(config_regularization, "alpha_cov"),
    alpha_coef = purrr::chuck(config_regularization, "alpha_coef"),
    alpha_spatial = purrr::chuck(config_regularization, "alpha_spatial"),
    lambda_cov = purrr::chuck(config_regularization, "lambda_cov"),
    lambda_coef = purrr::chuck(config_regularization, "lambda_coef"),
    lambda_spatial = purrr::chuck(
      config_regularization,
      "lambda_spatial"
    )
  )
list_usable_folds <-
  list_prepared_folds |>
  purrr::keep(
    ~ .x[["preparation_status"]] %in% base::c("ok", "prepared")
  )
if (
  base::length(list_usable_folds) == 0L
) {
  cli::cli_abort(
    "Calibration runner 02 found no usable cached prepared fold."
  )
}
list_reference_fold <-
  purrr::chuck(list_usable_folds, 1L, "list_prepared_fold")
formula_jsdm_environment <-
  list_reference_fold |>
  purrr::chuck("data_train_input", "data_abiotic_to_fit") |>
  build_jsdm_environment_formula(
    use_age = purrr::chuck(
      config_model_fitting,
      "use_age_in_formula"
    )
  )

config_fit_budget <-
  base::list(
    n_iter_initial = 500L,
    n_iter_max = 500L,
    n_sampling = 100L,
    n_step_size = NULL,
    n_early_stopping = NULL
  )
config_sjsdm_cv_fitting <-
  build_sjsdm_cross_validation_fitting_config(
    config_model_fitting = config_model_fitting,
    config_fit_budget = config_fit_budget
  )
calibration_input_hash <-
  digest::digest(
    base::list(
      calibration_contract_version = calibration_contract_version,
      data_candidates = data_candidates,
      list_prepared_folds = list_prepared_folds,
      formula_jsdm_environment = stringr::str_c(
        base::deparse(formula_jsdm_environment),
        collapse = ""
      ),
      config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
      repeat_confirmation_loss_tolerance =
        repeat_confirmation_loss_tolerance
    )
  )
previous_policy_calibration_input_hash <-
  digest::digest(
    base::list(
      calibration_contract_version = calibration_contract_version,
      data_candidates = data_candidates,
      list_prepared_folds = list_prepared_folds,
      formula_jsdm_environment = stringr::str_c(
        base::deparse(formula_jsdm_environment),
        collapse = ""
      ),
      config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
      repeat_confirmation_loss_tolerance = 0.01
    )
  )
legacy_calibration_input_hash <-
  digest::digest(
    base::list(
      calibration_contract_version =
        legacy_calibration_contract_version,
      data_candidates = data_candidates,
      list_prepared_folds = list_prepared_folds,
      formula_jsdm_environment = stringr::str_c(
        base::deparse(formula_jsdm_environment),
        collapse = ""
      ),
      config_sjsdm_cv_fitting = config_sjsdm_cv_fitting
    )
  )
if (
  !base::is.null(list_existing) &&
    base::identical(list_existing[["calibration_status"]], "accepted") &&
    base::identical(
      list_existing[["calibration_contract_version"]],
      calibration_contract_version
    ) &&
    base::identical(
      list_existing[["calibration_input_hash"]],
      calibration_input_hash
    )
) {
  cli::cli_inform("Reusing the completed content-matched calibration result.")
  base::quit(save = "no", status = 0L)
}
flag_reuse_stricter_v2_result <-
  !base::is.null(list_existing) &&
    base::identical(list_existing[["calibration_status"]], "accepted") &&
    base::identical(
      list_existing[["calibration_contract_version"]],
      legacy_calibration_contract_version
    ) &&
    base::identical(
      list_existing[["calibration_input_hash"]],
      legacy_calibration_input_hash
    )
flag_reuse_stricter_v3_policy_result <-
  !base::is.null(list_existing) &&
    base::identical(list_existing[["calibration_status"]], "accepted") &&
    base::identical(
      list_existing[["calibration_contract_version"]],
      calibration_contract_version
    ) &&
    base::identical(
      list_existing[["calibration_input_hash"]],
      previous_policy_calibration_input_hash
    )
if (
  flag_reuse_stricter_v2_result ||
    flag_reuse_stricter_v3_policy_result
) {
  migration_status <-
    if (
      flag_reuse_stricter_v2_result
    ) {
      "reused_stricter_v2_result"
    } else {
      "reused_stricter_v3_policy_result"
    }
  if (
    flag_reuse_stricter_v2_result
  ) {
    list_existing[["data_accepted_budget"]] <-
      list_existing[["data_accepted_budget"]] |>
      dplyr::mutate(
        repeat_two_candidate_id = .data[["candidate_id"]],
        repeat_two_exact_winner = TRUE,
        repeat_two_relative_loss_gap = 0,
        repeat_two_loss_tolerance =
          repeat_confirmation_loss_tolerance,
        repeat_two_practically_equivalent = TRUE,
        repeat_two_confirmed = TRUE
      )
  } else {
    list_existing[["data_accepted_budget"]] <-
      list_existing[["data_accepted_budget"]] |>
      dplyr::mutate(
        repeat_two_loss_tolerance =
          repeat_confirmation_loss_tolerance,
        repeat_two_practically_equivalent =
          .data[["repeat_two_exact_winner"]] |
          .data[["repeat_two_relative_loss_gap"]] <=
            repeat_confirmation_loss_tolerance,
        repeat_two_confirmed =
          .data[["repeat_two_practically_equivalent"]]
      )
  }
  list_existing[["calibration_contract_version"]] <-
    calibration_contract_version
  list_existing[["calibration_input_hash"]] <-
    calibration_input_hash
  list_existing[["checkpoint_migration_status"]] <-
    migration_status
  list_existing[["run_provenance"]] <-
    list_existing[["run_provenance"]] |>
    dplyr::mutate(
      calibration_contract_version = calibration_contract_version,
      calibration_input_hash = calibration_input_hash,
      migration_status = migration_status
    )

  qs2::qs_save(list_existing, file_result)
  readr::write_csv(
    list_existing[["data_accepted_budget"]],
    fs::path(path_report, "accepted_budget.csv"),
    na = "NA"
  )
  readr::write_csv(
    list_existing[["run_provenance"]],
    fs::path(path_report, "run_provenance.csv"),
    na = "NA"
  )
  cli::cli_inform(
    stringr::str_c(
      "Reused an accepted result from a stricter calibration policy and",
      "recorded current repeat-confirmation provenance.",
      sep = " "
    )
  )
  base::quit(save = "no", status = 0L)
}

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
    ),
    checkpoint_file = fs::path(
      path_output,
      "calibration_checkpoint.qs"
    ),
    repeat_confirmation_loss_tolerance =
      repeat_confirmation_loss_tolerance
  )
finished_at <-
  base::Sys.time()

list_result[["calibration_contract_version"]] <-
  calibration_contract_version
list_result[["calibration_input_hash"]] <-
  calibration_input_hash
checkpoint_migration_status <-
  list_result[["checkpoint_migration_status"]]
if (
  base::is.null(checkpoint_migration_status)
) {
  checkpoint_migration_status <-
    NA_character_
}

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
    calibration_contract_version = calibration_contract_version,
    calibration_input_hash = calibration_input_hash,
    calibration_status = list_result[["calibration_status"]],
    migration_status = checkpoint_migration_status
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

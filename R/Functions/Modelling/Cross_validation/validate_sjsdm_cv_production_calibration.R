#' @title Validate Calibration Evidence Before Production Tuning
#' @description
#' Rechecks current representative preparation and saved calibration inputs
#' before a production tier can launch tuning. A published label is not proof.
#' @param profile_id
#' Main spatial or paleo-temporal configuration profile.
#' @param data_representatives
#' Optional representative inventory. Defaults to the published CSV.
#' @param validate_preparation_function,validate_evidence_function
#' Injectable preparation freshness and calibration compatibility checks.
#' @param read_target_function,load_evidence_function
#' Injectable cached production target and calibration evidence readers.
#' @return Invisibly, `NULL` when the required evidence is compatible.
#' @examples
#' \dontrun{
#' validate_sjsdm_cv_production_calibration("project_modern_spatial_local")
#' }
#' @export
validate_sjsdm_cv_production_calibration <- function(
    profile_id,
    data_representatives = NULL,
    validate_preparation_function = validate_sjsdm_cv_preparation_freshness,
    validate_evidence_function = validate_sjsdm_cv_calibration_evidence,
    read_target_function = targets::tar_read_raw,
    load_evidence_function = qs2::qs_read) {
  if (
    base::is.null(data_representatives)
  ) {
    file_inventory <-
      here::here("Documentation/Reports/Model_calibration/",
        "sjsdm_cv_fit_budget/calibration_representatives.csv")
    assertthat::assert_that(base::file.exists(file_inventory),
      msg = stringr::str_c("First run stage 02: ",
        "R/02_Main_analyses/02_Model_calibration/01_run_model_calibration.R"))
    data_representatives <-
      readr::read_csv(file_inventory, show_col_types = FALSE)
  }
  flag_temporal <-
    stringr::str_detect(profile_id, "^project_paleo_temporal_")
  analysis_id <-
    if (
      flag_temporal
    ) {
      "paleo_temporal"
    } else {
      stringr::str_extract(profile_id, "(paleo|modern)_spatial")
    }
  tier_id <-
    if (
      flag_temporal
    ) {
      "continental"
    } else {
      stringr::str_extract(profile_id, "[^_]+$")
    }
  data_required <-
    data_representatives |>
    dplyr::filter(.data[["analysis_id"]] == .env[["analysis_id"]],
      .data[["tier_id"]] == .env[["tier_id"]])
  assertthat::assert_that(base::nrow(data_required) > 0L,
    msg = "No calibration representatives are registered; rerun stage 02.")
  for (
    index in base::seq_len(base::nrow(data_required))
  ) {
    data_unit <-
      data_required[index, , drop = FALSE]
    calibration_profile <-
      if (
        flag_temporal
      ) {
        stringr::str_c("project_paleo_temporal_",
          data_unit[["continent_id"]][[1L]])
      } else {
        profile_id
      }
    target_fold <-
      stringr::str_c("list_sjsdm_prepared_tuning_folds_",
        data_unit[["target_suffix"]][[1L]])
    target_config <-
      if (
        flag_temporal
      ) {
        "config_model_fitting"
      } else {
        stringr::str_c("config_model_fitting_",
          data_unit[["target_suffix"]][[1L]])
      }
    pipeline_id <-
      if (
        flag_temporal
      ) {
        "pipeline_paleo_temporal"
      } else {
        stringr::str_c("pipeline_", analysis_id, "_resolution")
      }
    withr::with_envvar(
      new = base::c(R_CONFIG_ACTIVE = calibration_profile),
      code = validate_preparation_function(
        pipeline_script = here::here("R", "Pipelines",
          stringr::str_c(pipeline_id, ".R")),
        store_path = data_unit[["store_path"]][[1L]],
        target_names = target_fold
      )
    )
    unit_id <-
      data_unit[["scale_id"]][[1L]]
    resolution_id <-
      data_unit[["resolution_id"]][[1L]]
    file_evidence <-
      here::here("Data/Temp/Sjsdm_cv_calibration", calibration_profile,
        unit_id, resolution_id, "calibration_result.qs")
    list_result <-
      base::tryCatch(load_evidence_function(file = file_evidence),
        error = function(error_condition) {
          cli::cli_abort(base::c(
            "Required production calibration evidence is unreadable.",
            "x" = "File: {file_evidence}",
            "i" = stringr::str_c("First run stage 02: ",
              "R/02_Main_analyses/02_Model_calibration/",
              "01_run_model_calibration.R")
          ))
        })
    list_check <-
      validate_evidence_function(
        list_result = list_result,
        list_prepared_folds = read_target_function(name = target_fold,
          store = data_unit[["store_path"]][[1L]]),
        config_model_fitting = read_target_function(name = target_config,
          store = data_unit[["store_path"]][[1L]])
      )
    if (
      !list_check[["status"]] %in% base::c("accepted", "compatible_legacy")
    ) {
      cli::cli_abort(base::c(
        "Production fitting is blocked by incompatible calibration.",
        "x" = "Representative: {calibration_profile}/{unit_id}",
        "x" = "Resolution: {resolution_id}",
        "i" = "Run stage 02 after resolving its reported blockers:",
        "i" = stringr::str_c("Rscript R/02_Main_analyses/",
          "02_Model_calibration/01_run_model_calibration.R"),
        "i" = "No tuning or final-model fit was launched."
      ))
    }
  }
  return(base::invisible(NULL))
}

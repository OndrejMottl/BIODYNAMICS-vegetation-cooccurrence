#' @title Compute Versioned Scientific Calibration Input Hashes
#' @description
#' Hashes analytical input content while retaining raw legacy signatures for
#' verified migrations. Per-fold fingerprints support later recovery audits.
#' @param data_candidates,list_prepared_folds,sel_abiotic_formula
#' Candidate grid, cached prepared folds and environment formula.
#' @param config_sjsdm_cv_fitting
#' Structural CV fitting configuration with the calibration starting budget.
#' @param repeat_confirmation_loss_tolerance
#' Maximum relative loss gap allowed for repeat-two confirmation.
#' @return Current and legacy input hashes and scientific input fingerprints.
#' @examples
#' \dontrun{
#' compute_sjsdm_cv_calibration_hashes(
#'   data_candidates, list_prepared_folds, ~ temperature, config_cv
#' )
#' }
#' @export
compute_sjsdm_cv_calibration_hashes <- function(
    data_candidates,
    list_prepared_folds,
    sel_abiotic_formula,
    config_sjsdm_cv_fitting,
    repeat_confirmation_loss_tolerance = 0.02) {
  assertthat::assert_that(
    base::is.data.frame(data_candidates),
    base::is.list(list_prepared_folds),
    base::is.list(config_sjsdm_cv_fitting),
    base::is.numeric(repeat_confirmation_loss_tolerance),
    base::length(repeat_confirmation_loss_tolerance) == 1L,
    base::is.finite(repeat_confirmation_loss_tolerance),
    repeat_confirmation_loss_tolerance >= 0,
    msg = "Calibration hash inputs are incomplete."
  )
  list_payload <-
    base::list(
      calibration_contract_version = "sjsdm_cv_adaptive_calibration_v3",
      data_candidates = data_candidates,
      list_prepared_folds = list_prepared_folds,
      formula_jsdm_environment = stringr::str_c(
        base::deparse(sel_abiotic_formula), collapse = ""
      ),
      config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
      repeat_confirmation_loss_tolerance =
        repeat_confirmation_loss_tolerance
    )
  hash_v3 <-
    digest::digest(list_payload)
  list_payload[["repeat_confirmation_loss_tolerance"]] <-
    0.01
  hash_v3_previous <-
    digest::digest(list_payload)
  list_payload[["repeat_confirmation_loss_tolerance"]] <-
    NULL
  list_payload[["calibration_contract_version"]] <-
    "sjsdm_cv_adaptive_calibration_v2"
  hash_v2 <-
    digest::digest(list_payload)
  list_payload[["calibration_contract_version"]] <-
    "sjsdm_cv_adaptive_calibration_v4"
  list_payload[["list_prepared_folds"]] <-
    prepare_sjsdm_cv_calibration_hash_folds(list_prepared_folds)
  list_payload[["repeat_confirmation_loss_tolerance"]] <-
    repeat_confirmation_loss_tolerance
  res <-
    base::list(
      calibration_contract_version =
        "sjsdm_cv_adaptive_calibration_v4",
      calibration_input_hash = digest::digest(list_payload),
      legacy_v3_hash = hash_v3,
      previous_policy_v3_hash = hash_v3_previous,
      legacy_v2_hash = hash_v2,
      fold_content_hashes = purrr::map_chr(
        list_payload[["list_prepared_folds"]], digest::digest
      ),
      candidate_content_hash = digest::digest(data_candidates),
      formula_content_hash = digest::digest(
        list_payload[["formula_jsdm_environment"]]
      ),
      fitting_content_hash = digest::digest(config_sjsdm_cv_fitting)
    )

  return(res)
}

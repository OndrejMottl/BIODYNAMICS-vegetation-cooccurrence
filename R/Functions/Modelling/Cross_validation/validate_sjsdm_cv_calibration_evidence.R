#' @title Validate Calibration Evidence Against Cached Analytical Inputs
#' @description
#' Reconstructs calibration signatures from production folds and structural
#' settings. Legacy results are eligible for migration only on an exact raw
#' input match; acceptance status alone is never sufficient for publication.
#' @param list_result
#' Saved calibration result, or `NULL` when unavailable.
#' @param list_prepared_folds,config_model_fitting
#' Current production fold records and final fitting configuration.
#' @return A compatibility status, migration status and input fingerprints.
#' @examples
#' \dontrun{
#' validate_sjsdm_cv_calibration_evidence(result, folds, config_model)
#' }
#' @export
validate_sjsdm_cv_calibration_evidence <- function(
    list_result,
    list_prepared_folds,
    config_model_fitting) {
  assertthat::assert_that(
    base::is.null(list_result) || base::is.list(list_result),
    base::is.list(list_prepared_folds),
    base::is.list(config_model_fitting),
    msg = "Calibration evidence and cached inputs must be lists."
  )
  list_usable <-
    purrr::keep(
      list_prepared_folds,
      ~ .x[["preparation_status"]] %in% base::c("ok", "prepared")
    )
  if (
    base::length(list_usable) == 0L ||
      base::length(list_usable) != base::length(list_prepared_folds)
  ) {
    return(base::list(
      status = "incomplete_preparation", migration_status = NA_character_,
      list_hashes = NULL
    ))
  }
  data_candidates <-
    base::do.call(
      build_sjsdm_regularization_candidates,
      purrr::chuck(config_model_fitting, "cross_validation", "regularization")
    )
  formula_environment <-
    build_jsdm_environment_formula(
      data = purrr::chuck(
        list_usable, 1L, "list_prepared_fold", "data_train_input",
        "data_abiotic_to_fit"
      ),
      use_age = purrr::chuck(config_model_fitting, "use_age_in_formula")
    )
  config_cv <-
    build_sjsdm_cross_validation_fitting_config(
      config_model_fitting = config_model_fitting,
      config_fit_budget = base::list(
        n_iter_initial = 500L, n_iter_max = 500L, n_sampling = 100L,
        n_step_size = NULL, n_early_stopping = NULL
      )
    )
  list_hashes <-
    compute_sjsdm_cv_calibration_hashes(
      data_candidates = data_candidates,
      list_prepared_folds = list_prepared_folds,
      sel_abiotic_formula = formula_environment,
      config_sjsdm_cv_fitting = config_cv
    )
  status <-
    "incompatible_inputs"
  migration_status <-
    NA_character_
  if (
    base::is.null(list_result)
  ) {
    status <-
      "missing"
  } else if (
    !base::identical(list_result[["calibration_status"]], "accepted")
  ) {
    status <-
      "not_accepted"
  } else {
    calibration_contract_version <-
      list_result[["calibration_contract_version"]]
    calibration_input_hash <-
      list_result[["calibration_input_hash"]]
    if (
      base::identical(
        calibration_contract_version,
        list_hashes[["calibration_contract_version"]]
      )
    ) {
      if (
        base::identical(
          calibration_input_hash, list_hashes[["calibration_input_hash"]]
        )
      ) {
        status <-
          "accepted"
      }
    } else if (
      base::identical(
        calibration_contract_version, "sjsdm_cv_adaptive_calibration_v3"
      ) && base::identical(
        calibration_input_hash, list_hashes[["legacy_v3_hash"]]
      )
    ) {
      status <-
        "compatible_legacy"
      migration_status <-
        "reused_content_matched_v3_result"
    } else if (
      base::identical(
        calibration_contract_version, "sjsdm_cv_adaptive_calibration_v3"
      ) && base::identical(
        calibration_input_hash, list_hashes[["previous_policy_v3_hash"]]
      )
    ) {
      status <-
        "compatible_legacy"
      migration_status <-
        "reused_stricter_v3_policy_result"
    } else if (
      base::identical(
        calibration_contract_version, "sjsdm_cv_adaptive_calibration_v2"
      ) && base::identical(
        calibration_input_hash, list_hashes[["legacy_v2_hash"]]
      )
    ) {
      status <-
        "compatible_legacy"
      migration_status <-
        "reused_stricter_v2_result"
    }
  }
  res <-
    base::list(
      status = status, migration_status = migration_status,
      list_hashes = list_hashes
    )

  return(res)
}

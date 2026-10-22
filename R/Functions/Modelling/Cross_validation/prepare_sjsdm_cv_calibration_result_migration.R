#' @title Prepare a Verified Calibration Evidence Migration
#' @description
#' Migrates content-matched calibration evidence without refitting models.
#' @param list_result
#' Accepted saved calibration result.
#' @param list_prepared_folds,config_model_fitting
#' Current production fold records and structural model configuration.
#' @param list_legacy_prepared_folds
#' Optional independently reconstructed original folds for operational-only
#' version-four migration. Exact original and current analytical proof is
#' required by [validate_sjsdm_cv_calibration_evidence()].
#' @param migrated_at
#' Explicit timestamp for the migration provenance.
#' @return A migrated result preserving fitting evidence and prior history.
#' @details
#' This function does not write files. Callers must archive the original
#' evidence before saving its result. An already-current result is unchanged.
#' @examples
#' \dontrun{
#' prepare_sjsdm_cv_calibration_result_migration(result, folds, config_model)
#' }
#' @export
prepare_sjsdm_cv_calibration_result_migration <- function(
    list_result,
    list_prepared_folds,
    config_model_fitting,
    list_legacy_prepared_folds = NULL,
    migrated_at = base::Sys.time()) {
  list_check <-
    validate_sjsdm_cv_calibration_evidence(
      list_result = list_result,
      list_prepared_folds = list_prepared_folds,
      config_model_fitting = config_model_fitting,
      list_legacy_prepared_folds = list_legacy_prepared_folds
    )
  if (
    list_check[["status"]] == "accepted"
  ) {
    return(list_result)
  }
  assertthat::assert_that(
    list_check[["status"]] == "compatible_legacy",
    base::inherits(migrated_at, "POSIXct"),
    base::length(migrated_at) == 1L,
    !base::is.na(migrated_at),
    msg = "Calibration migration requires verified compatible evidence."
  )
  list_hashes <-
    list_check[["list_hashes"]]
  migration_status <-
    list_check[["migration_status"]]
  list_migration_history <-
    purrr::pluck(list_result, "list_migration_history",
      .default = base::list())
  list_previous_identity <-
    list_result[base::c(
      "calibration_contract_version", "calibration_input_hash",
      "calibration_input_fingerprints", "run_provenance",
      "legacy_calibration_contract_version", "legacy_calibration_input_hash",
      "legacy_run_provenance", "checkpoint_migration_status"
    )]
  res <- list_result
  res[["list_migration_history"]] <-
    base::c(list_migration_history, base::list(list_previous_identity))
  if (
    migration_status == "reused_stricter_v2_result"
  ) {
    res[["data_accepted_budget"]] <-
      res[["data_accepted_budget"]] |>
      dplyr::mutate(
        repeat_two_candidate_id = .data[["candidate_id"]],
        repeat_two_exact_winner = TRUE,
        repeat_two_relative_loss_gap = 0,
        repeat_two_loss_tolerance = 0.02,
        repeat_two_practically_equivalent = TRUE,
        repeat_two_confirmed = TRUE
      )
  } else if (
    migration_status == "reused_stricter_v3_policy_result"
  ) {
    res[["data_accepted_budget"]] <-
      res[["data_accepted_budget"]] |>
      dplyr::mutate(
        repeat_two_loss_tolerance = 0.02,
        repeat_two_practically_equivalent =
          .data[["repeat_two_exact_winner"]] |
            .data[["repeat_two_relative_loss_gap"]] <= 0.02,
        repeat_two_confirmed = .data[["repeat_two_practically_equivalent"]]
      )
  }
  res[["legacy_calibration_input_hash"]] <-
    list_result[["calibration_input_hash"]]
  res[["legacy_calibration_contract_version"]] <-
    list_result[["calibration_contract_version"]]
  res[["legacy_run_provenance"]] <-
    list_result[["run_provenance"]]
  res[["calibration_input_fingerprints"]] <- list_hashes
  res[["calibration_contract_version"]] <-
    list_hashes[["calibration_contract_version"]]
  res[["calibration_input_hash"]] <-
    list_hashes[["calibration_input_hash"]]
  res[["checkpoint_migration_status"]] <- migration_status
  res[["run_provenance"]] <-
    list_result[["run_provenance"]] |>
    dplyr::mutate(
      calibration_contract_version = res[["calibration_contract_version"]],
      calibration_input_hash = res[["calibration_input_hash"]],
      legacy_calibration_contract_version =
        res[["legacy_calibration_contract_version"]],
      legacy_calibration_input_hash = res[["legacy_calibration_input_hash"]],
      hash_migrated_at = migrated_at,
      migration_status = .env[["migration_status"]]
    )
  return(res)
}

#' @title Audit Completed Continental sjSDM Results for Retention
#' @description
#' Retains a legacy continental regularization decision and final model only
#' when the final fit converged and calibrated evidence reproduces its winner.
#' @param data_completed
#' Completed unit-resolution rows with final convergence, legacy winner, and
#' explicit legacy CV/final fitting budgets.
#' @param data_calibration
#' Unit-resolution calibration rows with accepted status and winning candidate.
#' @return
#' Audit table with deterministic retention decisions and reasons.
#' @export
evaluate_sjsdm_continental_cv_retention <- function(
    data_completed = NULL,
    data_calibration = NULL) {
  vec_keys <-
    base::c("analysis_id", "continent_id", "resolution_id")
  vec_completed_columns <-
    base::c(
      vec_keys,
      "final_model_converged",
      "legacy_candidate_id",
      "legacy_cv_n_iter",
      "legacy_cv_n_sampling",
      "final_n_iter",
      "final_n_sampling"
    )
  vec_calibration_columns <-
    base::c(
      vec_keys,
      "calibration_status",
      "candidate_id",
      "n_iter_initial",
      "n_iter_max",
      "n_sampling"
    )

  assertthat::assert_that(
    base::is.data.frame(data_completed),
    base::all(vec_completed_columns %in% base::colnames(data_completed)),
    base::is.data.frame(data_calibration),
    base::all(vec_calibration_columns %in% base::colnames(data_calibration)),
    !base::any(base::duplicated(data_completed[vec_keys])),
    !base::any(base::duplicated(data_calibration[vec_keys])),
    msg = "Continental audit inputs are incomplete or duplicated."
  )

  res <-
    data_completed |>
    dplyr::left_join(data_calibration, by = vec_keys) |>
    dplyr::mutate(
      benchmark_accepted = .data[["calibration_status"]] == "accepted",
      winner_reproduced =
        .data[["legacy_candidate_id"]] == .data[["candidate_id"]],
      retention_status = dplyr::if_else(
        .data[["final_model_converged"]] %in% TRUE &
          .data[["benchmark_accepted"]] %in% TRUE &
          .data[["winner_reproduced"]] %in% TRUE,
        "retain",
        "invalidate_cv_and_model_descendants"
      ),
      retention_reason = dplyr::case_when(
        !(.data[["final_model_converged"]] %in% TRUE) ~
          "final_model_not_converged",
        !(.data[["benchmark_accepted"]] %in% TRUE) ~
          "calibration_not_accepted",
        !(.data[["winner_reproduced"]] %in% TRUE) ~
          "regularization_winner_changed",
        .default = "converged_and_winner_reproduced"
      )
    )

  return(res)
}

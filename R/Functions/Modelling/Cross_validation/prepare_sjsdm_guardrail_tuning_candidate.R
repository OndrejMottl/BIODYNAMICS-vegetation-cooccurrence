#' @title Prepare One Candidate's Tuning Guardrail Evidence
#' @description
#' Validates and reshapes complete repeat-level tuning evidence for one
#' candidate comparison.
#' @param data_tuning_summary
#' Repeat-by-candidate tuning summary.
#' @param selected_candidate_id
#' Candidate identifier to retain.
#' @param suffix
#' Suffix appended to metric columns.
#' @return
#' One row per repeat with suffixed tuning metrics.
#' @export
prepare_sjsdm_guardrail_tuning_candidate <- function(
    data_tuning_summary = NULL,
    selected_candidate_id = NULL,
    suffix = NULL) {
  vec_required_columns <-
    base::c(
      "repeat_id",
      "candidate_id",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "summary_status"
    )

  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::all(
      vec_required_columns %in% base::colnames(data_tuning_summary)
    ),
    base::is.character(selected_candidate_id),
    base::length(selected_candidate_id) == 1L,
    base::is.character(suffix),
    base::length(suffix) == 1L,
    msg = "Tuning guardrail inputs are incomplete."
  )

  data_selected <-
    data_tuning_summary |>
    dplyr::filter(
      .data[["candidate_id"]] == selected_candidate_id
    ) |>
    dplyr::select(
      "repeat_id",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "summary_status"
    )

  data_duplicate_repeats <-
    data_selected |>
    dplyr::count(.data[["repeat_id"]]) |>
    dplyr::filter(.data[["n"]] != 1L)

  if (
    base::nrow(data_selected) == 0L ||
      base::nrow(data_duplicate_repeats) > 0L ||
      !base::all(data_selected[["summary_status"]] == "ok") ||
      !base::all(
        base::is.finite(
          data_selected[["negative_log_likelihood_per_response"]]
        )
      ) ||
      !base::all(base::is.finite(data_selected[["auc_macro_test"]]))
  ) {
    cli::cli_abort(
      "Each assessed candidate must have one complete row per repeat."
    )
  }

  res <-
    data_selected |>
    dplyr::select(-"summary_status") |>
    dplyr::rename_with(
      ~ stringr::str_c(.x, suffix),
      -"repeat_id"
    )

  return(res)
}

#' @title Prepare One Candidate's Refit Guardrail Metrics
#' @description
#' Validates and reshapes complete fold-macro repeat metrics for one candidate.
#' @param data_metrics
#' Long repeat-metric evidence.
#' @param suffix
#' Suffix appended to metric columns.
#' @param guardrail_metrics
#' Required metric identifiers.
#' @return
#' One row per repeat with suffixed guardrail metrics.
#' @export
prepare_sjsdm_guardrail_repeat_metrics <- function(
    data_metrics = NULL,
    suffix = NULL,
    guardrail_metrics = base::c(
      "auc",
      "brier_score",
      "log_loss",
      "tjur_r2"
    )) {
  vec_required_columns <-
    base::c(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate"
    )

  assertthat::assert_that(
    base::is.data.frame(data_metrics),
    base::all(vec_required_columns %in% base::colnames(data_metrics)),
    base::is.character(suffix),
    base::length(suffix) == 1L,
    base::is.character(guardrail_metrics),
    base::length(guardrail_metrics) > 0L,
    msg = "Repeat guardrail inputs are incomplete."
  )

  data_selected <-
    data_metrics |>
    dplyr::filter(
      .data[["prediction_source"]] == "model",
      .data[["aggregation_id"]] == "fold_macro",
      .data[["metric_id"]] %in% guardrail_metrics
    ) |>
    dplyr::select("repeat_id", "metric_id", "estimate")

  data_duplicate_metrics <-
    data_selected |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["metric_id"]]
    ) |>
    dplyr::filter(.data[["n"]] != 1L)

  if (
    base::nrow(data_duplicate_metrics) > 0L ||
      base::nrow(data_selected) == 0L ||
      !base::all(base::is.finite(data_selected[["estimate"]]))
  ) {
    cli::cli_abort(
      "Repeat metrics must be unique, complete, and finite."
    )
  }

  data_wide <-
    data_selected |>
    tidyr::pivot_wider(
      names_from = "metric_id",
      values_from = "estimate"
    )

  flag_complete_repeat_metrics <-
    base::all(guardrail_metrics %in% base::colnames(data_wide)) &&
    base::all(
      base::is.finite(
        base::as.matrix(
          dplyr::select(
            data_wide,
            dplyr::all_of(guardrail_metrics)
          )
        )
      )
    )

  if (
    !flag_complete_repeat_metrics
  ) {
    cli::cli_abort(
      "Every repeat must contain every guardrail metric."
    )
  }

  res <-
    data_wide |>
    dplyr::rename_with(
      ~ stringr::str_c(.x, suffix),
      -"repeat_id"
    )

  return(res)
}

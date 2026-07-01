#' @title Select sjSDM Regularization
#' @description
#' Selects one regularization candidate from repeat-level tuning summaries.
#' @param data_tuning_summary
#' Repeat-by-candidate table returned by
#' [summarise_sjsdm_tuning_candidates()].
#' @param selection_metric
#' Metric minimized during selection. Defaults to normalized held-out negative
#' log likelihood, "negative_log_likelihood_per_response".
#' @return
#' One-row tibble containing the selected candidate parameters, criterion name
#' and value, repeat count, deterministic candidate rank, and regularization
#' source.
#' @details
#' A candidate is eligible only when every represented repeat is complete.
#' The selection metric is averaged equally across repeats. Lower values are
#' preferred, and exact ties are resolved by lexical candidate identifier.
#' @examples
#' \dontrun{
#' select_sjsdm_regularization(data_tuning_summary = data_summary)
#' }
#' @export
select_sjsdm_regularization <- function(
    data_tuning_summary = NULL,
    selection_metric = "negative_log_likelihood_per_response") {
  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::nrow(data_tuning_summary) > 0L,
    msg = "data_tuning_summary must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::is.character(selection_metric),
    base::length(selection_metric) == 1L,
    !base::is.na(selection_metric),
    base::nzchar(selection_metric),
    msg = "selection_metric must be one non-missing column name."
  )

  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_metadata_columns <-
    base::c(
      vec_parameter_columns,
      "cv_strategy",
      "regularization_source"
    )

  vec_required_columns <-
    base::c(
      "repeat_id",
      "candidate_id",
      vec_metadata_columns,
      "summary_status",
      selection_metric
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary is missing required columns."
  )

  assertthat::assert_that(
    base::is.numeric(data_tuning_summary[[selection_metric]]),
    msg = "selection_metric must identify a numeric column."
  )

  data_duplicate_repeats <-
    data_tuning_summary |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["candidate_id"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_repeats) > 0L
  ) {
    cli::cli_abort(
      "Each repeat and candidate combination must occur once."
    )
  }

  data_inconsistent_metadata <-
    data_tuning_summary |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_metadata_columns),
        ~ dplyr::n_distinct(.x, na.rm = FALSE)
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(
      dplyr::if_any(
        dplyr::all_of(vec_metadata_columns),
        ~ .x != 1L
      )
    )

  if (
    base::nrow(data_inconsistent_metadata) > 0L
  ) {
    cli::cli_abort(
      "Candidate parameters and provenance must be constant across repeats."
    )
  }

  vec_repeat_ids <-
    data_tuning_summary |>
    dplyr::distinct(.data[["repeat_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]]) |>
    dplyr::pull("repeat_id")

  n_repeats_expected <-
    base::length(vec_repeat_ids)

  data_candidate_ranking <-
    data_tuning_summary |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(vec_metadata_columns), dplyr::first),
      n_repeats = dplyr::n_distinct(.data[["repeat_id"]]),
      repeats_complete =
        .data[["n_repeats"]] == n_repeats_expected &&
        base::all(.data[["repeat_id"]] %in% vec_repeat_ids) &&
        base::all(.data[["summary_status"]] == "ok") &&
        base::all(base::is.finite(.data[[selection_metric]])),
      selection_metric_value = dplyr::if_else(
        .data[["repeats_complete"]],
        base::mean(.data[[selection_metric]]),
        NA_real_
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(.data[["repeats_complete"]]) |>
    dplyr::arrange(
      .data[["selection_metric_value"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::mutate(candidate_rank = dplyr::row_number())

  if (
    base::nrow(data_candidate_ranking) == 0L
  ) {
    cli::cli_abort("No candidate completed every repeat.")
  }

  res <-
    data_candidate_ranking |>
    dplyr::slice_head(n = 1L) |>
    dplyr::mutate(selection_metric = selection_metric) |>
    dplyr::select(
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
      "selection_metric",
      "selection_metric_value",
      "n_repeats",
      "candidate_rank",
      "cv_strategy",
      "regularization_source"
    )

  return(res)
}

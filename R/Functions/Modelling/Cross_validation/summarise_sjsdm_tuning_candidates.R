#' @title Summarise sjSDM Tuning Candidates
#' @description
#' Pools fold-level tuning metrics within each repeat and candidate while
#' retaining structured completeness diagnostics.
#' @param data_tuning
#' Candidate-by-fold table returned by [run_sjsdm_tuning_candidates()].
#' @return
#' Tibble with one row per repeat and candidate. Fold-normalized held-out
#' negative log likelihood is averaged equally across folds. Candidates are
#' eligible only when every fold in the repeat has status "ok" and finite
#' loss.
#' @details
#' Candidate parameters, cross-validation strategy, and regularization source
#' must be constant for a candidate within a repeat. Incomplete candidates are
#' retained with summary status "incomplete" and missing aggregate metrics.
#' @examples
#' \dontrun{
#' summarise_sjsdm_tuning_candidates(data_tuning = data_tuning)
#' }
#' @export
summarise_sjsdm_tuning_candidates <- function(data_tuning = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_tuning),
    base::nrow(data_tuning) > 0L,
    msg = "data_tuning must be a non-empty data frame."
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
      "fold_id",
      "candidate_id",
      vec_metadata_columns,
      "n_response_values",
      "negative_log_likelihood_test",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "fit_status"
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_tuning)),
    msg = "data_tuning is missing required columns."
  )

  assertthat::assert_that(
    base::is.character(data_tuning[["candidate_id"]]),
    base::is.character(data_tuning[["fit_status"]]),
    msg = "Candidate identifiers and fit statuses must be character."
  )

  data_duplicate_folds <-
    data_tuning |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_folds) > 0L
  ) {
    cli::cli_abort(
      "Each repeat, fold, and candidate combination must occur once."
    )
  }

  data_inconsistent_metadata <-
    data_tuning |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["candidate_id"]]
    ) |>
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
      "Candidate parameters and provenance must be constant within a repeat."
    )
  }

  data_tuning_status <-
    data_tuning |>
    dplyr::mutate(
      fold_successful =
        .data[["fit_status"]] == "ok" &
        base::is.finite(.data[["n_response_values"]]) &
        .data[["n_response_values"]] > 0L &
        base::is.finite(.data[["negative_log_likelihood_test"]]) &
        base::is.finite(
          .data[["negative_log_likelihood_per_response"]]
        )
    )

  res <-
    data_tuning_status |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(vec_metadata_columns), dplyr::first),
      n_folds_total = dplyr::n_distinct(.data[["fold_id"]]),
      n_folds_successful = base::sum(.data[["fold_successful"]]),
      candidate_complete = base::all(.data[["fold_successful"]]),
      n_response_values = dplyr::if_else(
        .data[["candidate_complete"]],
        base::sum(.data[["n_response_values"]]),
        NA_integer_
      ),
      negative_log_likelihood_test = dplyr::if_else(
        .data[["candidate_complete"]],
        base::sum(.data[["negative_log_likelihood_test"]]),
        NA_real_
      ),
      negative_log_likelihood_per_response = dplyr::if_else(
        .data[["candidate_complete"]],
        base::mean(
          .data[["negative_log_likelihood_per_response"]]
        ),
        NA_real_
      ),
      auc_macro_test = dplyr::if_else(
        .data[["candidate_complete"]] &
          base::any(!base::is.na(.data[["auc_macro_test"]])),
        base::mean(.data[["auc_macro_test"]], na.rm = TRUE),
        NA_real_
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      summary_status = dplyr::if_else(
        .data[["candidate_complete"]],
        "ok",
        "incomplete"
      )
    ) |>
    dplyr::select(
      "repeat_id",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
      "n_folds_total",
      "n_folds_successful",
      "n_response_values",
      "negative_log_likelihood_test",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "summary_status",
      "cv_strategy",
      "regularization_source"
    ) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["candidate_id"]])

  return(res)
}

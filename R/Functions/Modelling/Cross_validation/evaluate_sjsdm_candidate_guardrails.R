#' @title Assess sjSDM Candidate Guardrails
#' @description
#' Compares a tuning candidate with its reference across tuning repeats and an
#' independent fold-local refit.
#' @param data_tuning_summary
#' Repeat-by-candidate tuning summary.
#' @param data_candidate_repeat_metrics
#' Candidate repeat metrics from [summarise_sjsdm_fold_metrics()].
#' @param data_reference_repeat_metrics
#' Reference repeat metrics with the same schema as the candidate metrics.
#' @param candidate_id Candidate identifier to assess.
#' @param reference_candidate_id Reference identifier used for comparison.
#' @param maximum_discrimination_decrease
#' Largest allowed repeat-level decrease in AUC or Tjur R2. Defaults to `0.01`.
#' @param minimum_tjur_r2
#' Minimum candidate mean fold-macro Tjur R2. Defaults to `0.1`.
#' @return
#' A named list containing tuning-repeat comparisons, independent-refit
#' comparisons, and a one-row guardrail summary.
#' @details
#' Acceptance requires lower tuning NLL in every repeat, tuning AUC within the
#' discrimination tolerance, non-inferior independent-refit AUC, Tjur R2, log
#' loss, and Brier score in every repeat, and the scientific Tjur R2 gate.
#' @examples
#' \dontrun{
#' evaluate_sjsdm_candidate_guardrails(
#'   data_tuning_summary = data_tuning,
#'   data_candidate_repeat_metrics = data_candidate_metrics,
#'   data_reference_repeat_metrics = data_reference_metrics,
#'   candidate_id = "candidate_002",
#'   reference_candidate_id = "candidate_001"
#' )
#' }
#' @export
evaluate_sjsdm_candidate_guardrails <- function(
    data_tuning_summary = NULL,
    data_candidate_repeat_metrics = NULL,
    data_reference_repeat_metrics = NULL,
    candidate_id = NULL,
    reference_candidate_id = NULL,
    maximum_discrimination_decrease = 0.01,
    minimum_tjur_r2 = 0.1) {
  purrr::walk(
    base::list(
      data_tuning_summary,
      data_candidate_repeat_metrics,
      data_reference_repeat_metrics
    ),
    ~ assertthat::assert_that(
      base::is.data.frame(.x),
      msg = "All evidence inputs must be data frames."
    )
  )

  purrr::walk(
    base::list(candidate_id, reference_candidate_id),
    ~ assertthat::assert_that(
      base::is.character(.x),
      base::length(.x) == 1L,
      !base::is.na(.x),
      base::nzchar(.x),
      msg = "Candidate identifiers must be non-missing strings."
    )
  )

  assertthat::assert_that(
    candidate_id != reference_candidate_id,
    msg = "candidate_id and reference_candidate_id must differ."
  )

  flag_valid_discrimination_decrease <-
    base::is.numeric(maximum_discrimination_decrease) &&
    base::length(maximum_discrimination_decrease) == 1L &&
    base::is.finite(maximum_discrimination_decrease) &&
    maximum_discrimination_decrease >= 0

  assertthat::assert_that(
    flag_valid_discrimination_decrease,
    msg = "maximum_discrimination_decrease must be non-negative."
  )

  flag_valid_tjur_gate <-
    base::is.numeric(minimum_tjur_r2) &&
    base::length(minimum_tjur_r2) == 1L &&
    base::is.finite(minimum_tjur_r2)

  assertthat::assert_that(
    flag_valid_tjur_gate,
    msg = "minimum_tjur_r2 must be finite."
  )

  vec_tuning_columns <-
    base::c(
      "repeat_id",
      "candidate_id",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "summary_status"
    )

  assertthat::assert_that(
    base::all(
      vec_tuning_columns %in% base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary is missing required columns."
  )

  data_candidate_tuning <-
    prepare_sjsdm_guardrail_tuning_candidate(
      data_tuning_summary = data_tuning_summary,
      selected_candidate_id = candidate_id,
      suffix = "_candidate"
    )

  data_reference_tuning <-
    prepare_sjsdm_guardrail_tuning_candidate(
      data_tuning_summary = data_tuning_summary,
      selected_candidate_id = reference_candidate_id,
      suffix = "_reference"
    )

  data_tuning_comparison <-
    dplyr::inner_join(
      data_candidate_tuning,
      data_reference_tuning,
      by = "repeat_id",
      relationship = "one-to-one"
    )

  if (
    base::nrow(data_tuning_comparison) !=
      base::nrow(data_candidate_tuning) ||
    base::nrow(data_tuning_comparison) !=
      base::nrow(data_reference_tuning)
  ) {
    cli::cli_abort("Candidate and reference tuning repeats must match.")
  }

  comparison_tolerance <-
    base::sqrt(.Machine[["double.eps"]])

  data_tuning_repeat_comparison <-
    data_tuning_comparison |>
    dplyr::mutate(
      nll_improvement =
        .data[["negative_log_likelihood_per_response_reference"]] -
        .data[["negative_log_likelihood_per_response_candidate"]],
      auc_change = .data[["auc_macro_test_candidate"]] -
        .data[["auc_macro_test_reference"]],
      nll_improved = .data[["nll_improvement"]] > 0,
      auc_noninferior = .data[["auc_change"]] >=
        -maximum_discrimination_decrease - comparison_tolerance
    ) |>
    dplyr::arrange(.data[["repeat_id"]])

  vec_metric_columns <-
    base::c(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate"
    )

  purrr::walk(
    base::list(
      data_candidate_repeat_metrics,
      data_reference_repeat_metrics
    ),
    ~ assertthat::assert_that(
      base::all(vec_metric_columns %in% base::colnames(.x)),
      msg = "Repeat metric evidence is missing required columns."
    )
  )

  vec_guardrail_metrics <-
    base::c("auc", "brier_score", "log_loss", "tjur_r2")

  data_candidate_refit <-
    prepare_sjsdm_guardrail_repeat_metrics(
      data_metrics = data_candidate_repeat_metrics,
      suffix = "_candidate",
      guardrail_metrics = vec_guardrail_metrics
    )

  data_reference_refit <-
    prepare_sjsdm_guardrail_repeat_metrics(
      data_metrics = data_reference_repeat_metrics,
      suffix = "_reference",
      guardrail_metrics = vec_guardrail_metrics
    )

  data_refit_comparison <-
    dplyr::inner_join(
      data_candidate_refit,
      data_reference_refit,
      by = "repeat_id",
      relationship = "one-to-one"
    )

  if (
    base::nrow(data_refit_comparison) !=
      base::nrow(data_candidate_refit) ||
    base::nrow(data_refit_comparison) !=
      base::nrow(data_reference_refit)
  ) {
    cli::cli_abort("Candidate and reference refit repeats must match.")
  }

  data_refit_repeat_comparison <-
    data_refit_comparison |>
    dplyr::mutate(
      auc_change = .data[["auc_candidate"]] -
        .data[["auc_reference"]],
      tjur_r2_change = .data[["tjur_r2_candidate"]] -
        .data[["tjur_r2_reference"]],
      log_loss_change = .data[["log_loss_candidate"]] -
        .data[["log_loss_reference"]],
      brier_score_change = .data[["brier_score_candidate"]] -
        .data[["brier_score_reference"]],
      refit_noninferior =
        .data[["auc_change"]] >=
          -maximum_discrimination_decrease - comparison_tolerance &
        .data[["tjur_r2_change"]] >=
          -maximum_discrimination_decrease - comparison_tolerance &
        .data[["log_loss_change"]] <= comparison_tolerance &
        .data[["brier_score_change"]] <= comparison_tolerance
    ) |>
    dplyr::arrange(.data[["repeat_id"]])

  flag_nll_improved <-
    base::all(data_tuning_repeat_comparison[["nll_improved"]])

  flag_tuning_auc_noninferior <-
    base::all(data_tuning_repeat_comparison[["auc_noninferior"]])

  flag_refit_noninferior <-
    base::all(data_refit_repeat_comparison[["refit_noninferior"]])

  mean_candidate_tjur_r2 <-
    base::mean(data_refit_repeat_comparison[["tjur_r2_candidate"]])

  flag_scientific_tjur_gate <-
    mean_candidate_tjur_r2 >= minimum_tjur_r2

  vec_failed_guardrails <-
    base::c(
      if (
        !flag_nll_improved
      ) {
        "tuning_nll_not_improved_every_repeat"
      },
      if (
        !flag_tuning_auc_noninferior
      ) {
        "tuning_auc_deterioration"
      },
      if (
        !flag_refit_noninferior
      ) {
        "independent_refit_deterioration"
      },
      if (
        !flag_scientific_tjur_gate
      ) {
        "scientific_tjur_gate_failed"
      }
    )

  flag_eligible <-
    base::length(vec_failed_guardrails) == 0L

  data_guardrail_summary <-
    tibble::tibble(
      candidate_id = candidate_id,
      reference_candidate_id = reference_candidate_id,
      n_repeats = base::nrow(data_tuning_repeat_comparison),
      n_repeats_nll_improved = base::sum(
        data_tuning_repeat_comparison[["nll_improved"]]
      ),
      tuning_nll_improved_all_repeats = flag_nll_improved,
      tuning_auc_noninferior_all_repeats =
        flag_tuning_auc_noninferior,
      independent_refit_noninferior_all_repeats =
        flag_refit_noninferior,
      mean_candidate_tjur_r2 = mean_candidate_tjur_r2,
      minimum_tjur_r2 = minimum_tjur_r2,
      scientific_tjur_gate_passed = flag_scientific_tjur_gate,
      maximum_discrimination_decrease =
        maximum_discrimination_decrease,
      eligible = flag_eligible,
      selection_guardrail_status = dplyr::if_else(
        flag_eligible,
        "eligible",
        "rejected"
      ),
      failed_guardrails = dplyr::if_else(
        flag_eligible,
        NA_character_,
        stringr::str_c(vec_failed_guardrails, collapse = ";")
      )
    )

  res <-
    base::list(
      data_tuning_repeat_comparison =
        data_tuning_repeat_comparison,
      data_refit_repeat_comparison =
        data_refit_repeat_comparison,
      data_guardrail_summary = data_guardrail_summary
    )

  return(res)
}

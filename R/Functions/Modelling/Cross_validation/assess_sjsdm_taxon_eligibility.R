#' @title Assess sjSDM Taxon Eligibility
#' @description
#' Applies prespecified prevalence and fold-evaluability rules to fold-local
#' sjSDM metrics.
#' @param data_fold_metrics
#' Fold-local metric table returned by [evaluate_sjsdm_fold_predictions()].
#' @param minimum_prevalence
#' Minimum observation-weighted prevalence. Defaults to `0.05`.
#' @param maximum_prevalence
#' Maximum observation-weighted prevalence. Defaults to `0.95`.
#' @param minimum_evaluable_fraction
#' Minimum fraction of folds with an evaluable model Tjur R2. Defaults to
#' `0.8`.
#' @return
#' One-row-per-taxon tibble with prevalence, fold coverage, mean evaluable
#' Tjur R2, component checks, overall eligibility, and a deterministic status.
#' @details
#' Eligibility is based only on model Tjur R2 rows. Prevalence is calculated
#' from summed held-out presences and observations so unequal folds are weighted
#' by their observation counts.
#' @examples
#' \dontrun{
#' assess_sjsdm_taxon_eligibility(data_fold_metrics = data_metrics)
#' }
#' @export
assess_sjsdm_taxon_eligibility <- function(
    data_fold_metrics = NULL,
    minimum_prevalence = 0.05,
    maximum_prevalence = 0.95,
    minimum_evaluable_fraction = 0.8) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_metrics),
    msg = "data_fold_metrics must be a data frame."
  )

  vec_required_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "taxon",
      "prediction_source",
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_fold_metrics)
    ),
    msg = "data_fold_metrics is missing required columns."
  )

  flag_valid_prevalence <-
    base::is.numeric(minimum_prevalence) &&
    base::length(minimum_prevalence) == 1L &&
    base::is.finite(minimum_prevalence) &&
    base::is.numeric(maximum_prevalence) &&
    base::length(maximum_prevalence) == 1L &&
    base::is.finite(maximum_prevalence) &&
    minimum_prevalence >= 0 &&
    maximum_prevalence <= 1 &&
    minimum_prevalence < maximum_prevalence

  assertthat::assert_that(
    flag_valid_prevalence,
    msg = "The prevalence thresholds must satisfy 0 <= minimum < maximum <= 1."
  )

  flag_valid_evaluable_fraction <-
    base::is.numeric(minimum_evaluable_fraction) &&
    base::length(minimum_evaluable_fraction) == 1L &&
    base::is.finite(minimum_evaluable_fraction) &&
    minimum_evaluable_fraction > 0 &&
    minimum_evaluable_fraction <= 1

  assertthat::assert_that(
    flag_valid_evaluable_fraction,
    msg = "minimum_evaluable_fraction must be in (0, 1]."
  )

  data_tjur <-
    data_fold_metrics |>
    dplyr::filter(
      .data[["prediction_source"]] == "model",
      .data[["metric_id"]] == "tjur_r2"
    )

  data_duplicate_keys <-
    data_tjur |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["taxon"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_keys) > 0L
  ) {
    cli::cli_abort("Repeat, fold, and taxon Tjur keys must be unique.")
  }

  data_taxon_summary <-
    data_tjur |>
    dplyr::group_by(.data[["taxon"]]) |>
    dplyr::summarise(
      n_folds_total = dplyr::n(),
      n_folds_evaluable = base::sum(
        .data[["metric_status"]] == "ok" &
          base::is.finite(.data[["estimate"]])
      ),
      n_observations = base::sum(.data[["n_observations"]]),
      n_presences = base::sum(.data[["n_presences"]]),
      mean_tjur_r2 = dplyr::if_else(
        .data[["n_folds_evaluable"]] > 0L,
        base::mean(
          .data[["estimate"]][
            .data[["metric_status"]] == "ok" &
              base::is.finite(.data[["estimate"]])
          ]
        ),
        NA_real_
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      prevalence = .data[["n_presences"]] /
        .data[["n_observations"]],
      evaluable_fold_fraction = .data[["n_folds_evaluable"]] /
        .data[["n_folds_total"]],
      prevalence_above_minimum =
        .data[["prevalence"]] >= minimum_prevalence,
      prevalence_below_maximum =
        .data[["prevalence"]] <= maximum_prevalence,
      sufficient_evaluable_folds =
        .data[["evaluable_fold_fraction"]] >=
        minimum_evaluable_fraction,
      eligible = .data[["prevalence_above_minimum"]] &
        .data[["prevalence_below_maximum"]] &
        .data[["sufficient_evaluable_folds"]],
      eligibility_status = dplyr::case_when(
        !.data[["prevalence_above_minimum"]] &
          !.data[["sufficient_evaluable_folds"]] ~
          stringr::str_c(
            "prevalence_below_minimum;",
            "insufficient_evaluable_folds"
          ),
        !.data[["prevalence_below_maximum"]] &
          !.data[["sufficient_evaluable_folds"]] ~
          stringr::str_c(
            "prevalence_above_maximum;",
            "insufficient_evaluable_folds"
          ),
        !.data[["prevalence_above_minimum"]] ~
          "prevalence_below_minimum",
        !.data[["prevalence_below_maximum"]] ~
          "prevalence_above_maximum",
        !.data[["sufficient_evaluable_folds"]] ~
          "insufficient_evaluable_folds",
        TRUE ~ "eligible"
      )
    ) |>
    dplyr::arrange(.data[["taxon"]])

  return(data_taxon_summary)
}

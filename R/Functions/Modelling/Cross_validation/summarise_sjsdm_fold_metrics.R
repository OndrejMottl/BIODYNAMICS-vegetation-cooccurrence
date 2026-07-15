#' @title Summarise sjSDM Fold Metrics
#' @description
#' Aggregates fold-local sjSDM prediction metrics without pooling predictions
#' from separately fitted models.
#' @param data_fold_metrics
#' Long metric table returned by [evaluate_sjsdm_fold_predictions()].
#' @return
#' Named list containing `data_source_summaries` and
#' `data_paired_improvements`. Both tables contain repeat-level fold-macro and
#' observation-weighted estimates with fold, taxon, observation, and class
#' coverage. Paired improvements are positive when the model is better than the
#' prevalence null.
#' @details
#' Paired improvements use model-minus-null for Tjur R2 and AUC, and
#' null-minus-model for log loss and Brier score. Calibration coefficients are
#' summarised by source but are not converted to directional improvements.
#' @examples
#' \dontrun{
#' summarise_sjsdm_fold_metrics(
#'   data_fold_metrics = data_fold_metrics
#' )
#' }
#' @export
summarise_sjsdm_fold_metrics <- function(data_fold_metrics = NULL) {
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
      "n_presences",
      "n_absences",
      "prevalence"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_fold_metrics)
    ),
    msg = "data_fold_metrics must preserve all required columns."
  )

  assertthat::assert_that(
    base::is.numeric(data_fold_metrics[["repeat_id"]]),
    base::is.numeric(data_fold_metrics[["fold_id"]]),
    base::is.character(data_fold_metrics[["taxon"]]),
    base::is.character(data_fold_metrics[["prediction_source"]]),
    base::is.character(data_fold_metrics[["metric_id"]]),
    base::is.numeric(data_fold_metrics[["estimate"]]),
    base::is.character(data_fold_metrics[["metric_status"]]),
    base::is.numeric(data_fold_metrics[["n_observations"]]),
    base::is.numeric(data_fold_metrics[["n_presences"]]),
    base::is.numeric(data_fold_metrics[["n_absences"]]),
    base::is.numeric(data_fold_metrics[["prevalence"]]),
    msg = "data_fold_metrics columns have invalid types."
  )

  data_empty_source <-
    tibble::tibble(
      repeat_id = base::integer(),
      prediction_source = base::character(),
      metric_id = base::character(),
      aggregation_id = base::character(),
      estimate = base::numeric(),
      n_evaluable_fold_taxa = base::integer(),
      n_total_fold_taxa = base::integer(),
      fold_taxon_coverage = base::numeric(),
      n_folds_evaluable = base::integer(),
      n_folds_total = base::integer(),
      n_taxa_evaluable = base::integer(),
      n_taxa_total = base::integer(),
      n_observations_evaluable = base::integer(),
      n_presences_evaluable = base::integer(),
      n_absences_evaluable = base::integer(),
      prevalence = base::numeric()
    )

  data_empty_paired <-
    tibble::tibble(
      repeat_id = base::integer(),
      metric_id = base::character(),
      improvement_direction = base::character(),
      aggregation_id = base::character(),
      estimate = base::numeric(),
      n_evaluable_fold_taxa = base::integer(),
      n_total_fold_taxa = base::integer(),
      fold_taxon_coverage = base::numeric(),
      n_folds_evaluable = base::integer(),
      n_folds_total = base::integer(),
      n_taxa_evaluable = base::integer(),
      n_taxa_total = base::integer(),
      n_observations_evaluable = base::integer(),
      n_presences_evaluable = base::integer(),
      n_absences_evaluable = base::integer(),
      prevalence = base::numeric()
    )

  if (
    base::nrow(data_fold_metrics) == 0L
  ) {
    res_empty <-
      base::list(
        data_source_summaries = data_empty_source,
        data_paired_improvements = data_empty_paired
      )

    return(res_empty)
  }

  data_duplicate_keys <-
    data_fold_metrics |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["taxon"]],
      .data[["prediction_source"]],
      .data[["metric_id"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_keys) > 0L
  ) {
    cli::cli_abort(
      "Repeat, fold, taxon, source, and metric keys must be unique."
    )
  }

  flag_valid_sources <-
    base::all(
      data_fold_metrics[["prediction_source"]] %in%
        base::c("model", "prevalence_null")
    )

  if (
    !flag_valid_sources
  ) {
    cli::cli_abort(
      "Prediction sources must be model or prevalence_null."
    )
  }

  flag_valid_counts <-
    base::all(base::is.finite(data_fold_metrics[["n_observations"]])) &&
    base::all(base::is.finite(data_fold_metrics[["n_presences"]])) &&
    base::all(base::is.finite(data_fold_metrics[["n_absences"]])) &&
    base::all(data_fold_metrics[["n_observations"]] > 0) &&
    base::all(data_fold_metrics[["n_presences"]] >= 0) &&
    base::all(data_fold_metrics[["n_absences"]] >= 0) &&
    base::all(
      data_fold_metrics[["n_presences"]] +
        data_fold_metrics[["n_absences"]] ==
        data_fold_metrics[["n_observations"]]
    )

  if (
    !flag_valid_counts
  ) {
    cli::cli_abort("Observation and class counts are inconsistent.")
  }

  flag_valid_prevalence <-
    base::all(base::is.finite(data_fold_metrics[["prevalence"]])) &&
    base::all(
      base::abs(
        data_fold_metrics[["prevalence"]] -
          data_fold_metrics[["n_presences"]] /
          data_fold_metrics[["n_observations"]]
      ) < 1e-10
    )

  if (
    !flag_valid_prevalence
  ) {
    cli::cli_abort("Prevalence must agree with the class counts.")
  }

  data_ok_metrics <-
    data_fold_metrics |>
    dplyr::filter(.data[["metric_status"]] == "ok")

  if (
    !base::all(base::is.finite(data_ok_metrics[["estimate"]]))
  ) {
    cli::cli_abort("Metrics with status ok must have finite estimates.")
  }

  vec_aggregation_ids <-
    base::c("fold_macro", "observation_weighted")

  data_source_totals <-
    data_fold_metrics |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["prediction_source"]],
      .data[["metric_id"]]
    ) |>
    dplyr::summarise(
      n_total_fold_taxa = dplyr::n(),
      n_folds_total = dplyr::n_distinct(.data[["fold_id"]]),
      n_taxa_total = dplyr::n_distinct(.data[["taxon"]]),
      .groups = "drop"
    )

  data_source_evaluable <-
    data_ok_metrics |>
    tidyr::crossing(aggregation_id = vec_aggregation_ids) |>
    dplyr::mutate(
      aggregation_weight = dplyr::if_else(
        .data[["aggregation_id"]] == "fold_macro",
        1,
        base::as.numeric(.data[["n_observations"]])
      )
    ) |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["prediction_source"]],
      .data[["metric_id"]],
      .data[["aggregation_id"]]
    ) |>
    dplyr::summarise(
      estimate = stats::weighted.mean(
        x = .data[["estimate"]],
        w = .data[["aggregation_weight"]]
      ),
      n_evaluable_fold_taxa = dplyr::n(),
      n_folds_evaluable = dplyr::n_distinct(.data[["fold_id"]]),
      n_taxa_evaluable = dplyr::n_distinct(.data[["taxon"]]),
      n_observations_evaluable = base::sum(.data[["n_observations"]]),
      n_presences_evaluable = base::sum(.data[["n_presences"]]),
      n_absences_evaluable = base::sum(.data[["n_absences"]]),
      prevalence = stats::weighted.mean(
        x = .data[["prevalence"]],
        w = .data[["aggregation_weight"]]
      ),
      .groups = "drop"
    )

  data_source_summaries <-
    tidyr::crossing(
      data_source_totals,
      aggregation_id = vec_aggregation_ids
    ) |>
    dplyr::left_join(
      data_source_evaluable,
      by = base::c(
        "repeat_id",
        "prediction_source",
        "metric_id",
        "aggregation_id"
      )
    ) |>
    dplyr::mutate(
      n_evaluable_fold_taxa = dplyr::coalesce(
        .data[["n_evaluable_fold_taxa"]],
        0L
      ),
      n_folds_evaluable = dplyr::coalesce(
        .data[["n_folds_evaluable"]],
        0L
      ),
      n_taxa_evaluable = dplyr::coalesce(
        .data[["n_taxa_evaluable"]],
        0L
      ),
      n_observations_evaluable = dplyr::coalesce(
        .data[["n_observations_evaluable"]],
        0L
      ),
      n_presences_evaluable = dplyr::coalesce(
        .data[["n_presences_evaluable"]],
        0L
      ),
      n_absences_evaluable = dplyr::coalesce(
        .data[["n_absences_evaluable"]],
        0L
      ),
      fold_taxon_coverage = .data[["n_evaluable_fold_taxa"]] /
        .data[["n_total_fold_taxa"]]
    ) |>
    dplyr::select(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate",
      "n_evaluable_fold_taxa",
      "n_total_fold_taxa",
      "fold_taxon_coverage",
      "n_folds_evaluable",
      "n_folds_total",
      "n_taxa_evaluable",
      "n_taxa_total",
      "n_observations_evaluable",
      "n_presences_evaluable",
      "n_absences_evaluable",
      "prevalence"
    ) |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["prediction_source"]],
      .data[["metric_id"]],
      base::match(.data[["aggregation_id"]], vec_aggregation_ids)
    )

  vec_paired_metric_ids <-
    base::c("tjur_r2", "auc", "log_loss", "brier_score")

  vec_pair_keys <-
    base::c("repeat_id", "fold_id", "taxon", "metric_id")

  data_model_metrics <-
    data_fold_metrics |>
    dplyr::filter(
      .data[["prediction_source"]] == "model",
      .data[["metric_id"]] %in% vec_paired_metric_ids
    ) |>
    dplyr::select(
      dplyr::all_of(vec_pair_keys),
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    ) |>
    dplyr::rename(
      estimate_model = "estimate",
      metric_status_model = "metric_status"
    )

  data_null_metrics <-
    data_fold_metrics |>
    dplyr::filter(
      .data[["prediction_source"]] == "prevalence_null",
      .data[["metric_id"]] %in% vec_paired_metric_ids
    ) |>
    dplyr::select(
      dplyr::all_of(vec_pair_keys),
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    ) |>
    dplyr::rename(
      estimate_null = "estimate",
      metric_status_null = "metric_status",
      n_observations_null = "n_observations",
      n_presences_null = "n_presences",
      n_absences_null = "n_absences",
      prevalence_null = "prevalence"
    )

  data_paired_fold_metrics <-
    dplyr::inner_join(
      data_model_metrics,
      data_null_metrics,
      by = vec_pair_keys
    )

  if (
    base::nrow(data_paired_fold_metrics) == 0L
  ) {
    res_no_pairs <-
      base::list(
        data_source_summaries = data_source_summaries,
        data_paired_improvements = data_empty_paired
      )

    return(res_no_pairs)
  }

  if (
    !base::all(
      data_paired_fold_metrics[["n_observations"]] ==
        data_paired_fold_metrics[["n_observations_null"]]
    )
  ) {
    cli::cli_abort(
      "Paired model and null metrics must have identical observation counts."
    )
  }

  flag_identical_pair_classes <-
    base::all(
      data_paired_fold_metrics[["n_presences"]] ==
        data_paired_fold_metrics[["n_presences_null"]]
    ) &&
    base::all(
      data_paired_fold_metrics[["n_absences"]] ==
        data_paired_fold_metrics[["n_absences_null"]]
    ) &&
    base::all(
      data_paired_fold_metrics[["prevalence"]] ==
        data_paired_fold_metrics[["prevalence_null"]]
    )

  if (
    !flag_identical_pair_classes
  ) {
    cli::cli_abort(
      "Paired model and null metrics must have identical class counts."
    )
  }

  data_paired_values <-
    data_paired_fold_metrics |>
    dplyr::mutate(
      improvement_direction = dplyr::case_when(
        .data[["metric_id"]] %in% base::c("tjur_r2", "auc") ~
          "model_minus_null",
        .default = "null_minus_model"
      ),
      paired_estimate = dplyr::case_when(
        .data[["improvement_direction"]] == "model_minus_null" ~
          .data[["estimate_model"]] - .data[["estimate_null"]],
        .default = .data[["estimate_null"]] -
          .data[["estimate_model"]]
      ),
      pair_status = dplyr::if_else(
        .data[["metric_status_model"]] == "ok" &
          .data[["metric_status_null"]] == "ok",
        "ok",
        "not_evaluable"
      )
    )

  data_paired_totals <-
    data_paired_values |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["metric_id"]],
      .data[["improvement_direction"]]
    ) |>
    dplyr::summarise(
      n_total_fold_taxa = dplyr::n(),
      n_folds_total = dplyr::n_distinct(.data[["fold_id"]]),
      n_taxa_total = dplyr::n_distinct(.data[["taxon"]]),
      .groups = "drop"
    )

  data_paired_evaluable <-
    data_paired_values |>
    dplyr::filter(.data[["pair_status"]] == "ok") |>
    tidyr::crossing(aggregation_id = vec_aggregation_ids) |>
    dplyr::mutate(
      aggregation_weight = dplyr::if_else(
        .data[["aggregation_id"]] == "fold_macro",
        1,
        base::as.numeric(.data[["n_observations"]])
      )
    ) |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["metric_id"]],
      .data[["improvement_direction"]],
      .data[["aggregation_id"]]
    ) |>
    dplyr::summarise(
      estimate = stats::weighted.mean(
        x = .data[["paired_estimate"]],
        w = .data[["aggregation_weight"]]
      ),
      n_evaluable_fold_taxa = dplyr::n(),
      n_folds_evaluable = dplyr::n_distinct(.data[["fold_id"]]),
      n_taxa_evaluable = dplyr::n_distinct(.data[["taxon"]]),
      n_observations_evaluable = base::sum(.data[["n_observations"]]),
      n_presences_evaluable = base::sum(.data[["n_presences"]]),
      n_absences_evaluable = base::sum(.data[["n_absences"]]),
      prevalence = stats::weighted.mean(
        x = .data[["prevalence"]],
        w = .data[["aggregation_weight"]]
      ),
      .groups = "drop"
    )

  data_paired_improvements <-
    tidyr::crossing(
      data_paired_totals,
      aggregation_id = vec_aggregation_ids
    ) |>
    dplyr::left_join(
      data_paired_evaluable,
      by = base::c(
        "repeat_id",
        "metric_id",
        "improvement_direction",
        "aggregation_id"
      )
    ) |>
    dplyr::mutate(
      n_evaluable_fold_taxa = dplyr::coalesce(
        .data[["n_evaluable_fold_taxa"]],
        0L
      ),
      n_folds_evaluable = dplyr::coalesce(
        .data[["n_folds_evaluable"]],
        0L
      ),
      n_taxa_evaluable = dplyr::coalesce(
        .data[["n_taxa_evaluable"]],
        0L
      ),
      n_observations_evaluable = dplyr::coalesce(
        .data[["n_observations_evaluable"]],
        0L
      ),
      n_presences_evaluable = dplyr::coalesce(
        .data[["n_presences_evaluable"]],
        0L
      ),
      n_absences_evaluable = dplyr::coalesce(
        .data[["n_absences_evaluable"]],
        0L
      ),
      fold_taxon_coverage = .data[["n_evaluable_fold_taxa"]] /
        .data[["n_total_fold_taxa"]]
    ) |>
    dplyr::select(
      "repeat_id",
      "metric_id",
      "improvement_direction",
      "aggregation_id",
      "estimate",
      "n_evaluable_fold_taxa",
      "n_total_fold_taxa",
      "fold_taxon_coverage",
      "n_folds_evaluable",
      "n_folds_total",
      "n_taxa_evaluable",
      "n_taxa_total",
      "n_observations_evaluable",
      "n_presences_evaluable",
      "n_absences_evaluable",
      "prevalence"
    ) |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["metric_id"]],
      base::match(.data[["aggregation_id"]], vec_aggregation_ids)
    )

  res <-
    base::list(
      data_source_summaries = data_source_summaries,
      data_paired_improvements = data_paired_improvements
    )

  return(res)
}

#' @title Summarise Spatial MEM Benchmark Predictions
#' @description
#' Converts paired exact or fast out-of-fold predictions into one benchmark
#' row per repetition using the shared fold-local evaluation definitions.
#' @param data_predictions
#' Long out-of-fold prediction table accepted by
#' [evaluate_sjsdm_fold_predictions()].
#' @param spatial_mev_strategy
#' Spatial MEM strategy used to produce the predictions.
#' @param technical_cv_status
#' Technical status recorded for the benchmark run.
#' @param assignment_hash,artifact_schema_hash
#' Stable identifiers used to verify paired technical equivalence.
#' @return
#' Tibble with one row per repetition and spatial MEM strategy.
#' @export
summarise_spatial_mev_benchmark_predictions <- function(
    data_predictions = NULL,
    spatial_mev_strategy = NULL,
    technical_cv_status = "pass",
    assignment_hash = NULL,
    artifact_schema_hash = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_predictions),
    base::is.character(spatial_mev_strategy),
    base::length(spatial_mev_strategy) == 1L,
    spatial_mev_strategy %in% base::c("exact", "fast"),
    base::is.character(technical_cv_status),
    base::length(technical_cv_status) == 1L,
    base::is.character(assignment_hash),
    base::length(assignment_hash) == 1L,
    base::nzchar(assignment_hash),
    base::is.character(artifact_schema_hash),
    base::length(artifact_schema_hash) == 1L,
    base::nzchar(artifact_schema_hash),
    msg = "Benchmark predictions and identifiers must be complete."
  )

  data_fold_metrics <-
    evaluate_sjsdm_fold_predictions(
      data_predictions = data_predictions
    )

  data_source_summaries <-
    summarise_sjsdm_fold_metrics(
      data_fold_metrics = data_fold_metrics
    ) |>
    purrr::chuck("data_source_summaries") |>
    dplyr::filter(
      .data[["prediction_source"]] == "model",
      .data[["aggregation_id"]] == "fold_macro",
      .data[["metric_id"]] %in%
        base::c("log_loss", "auc", "tjur_r2")
    )

  data_metric_values <-
    data_source_summaries |>
    dplyr::select(
      "repeat_id",
      "metric_id",
      "estimate",
      "fold_taxon_coverage"
    ) |>
    tidyr::pivot_wider(
      names_from = "metric_id",
      values_from = "estimate"
    )

  data_coverage <-
    data_source_summaries |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::summarise(
      evaluable_taxon_coverage =
        base::min(.data[["fold_taxon_coverage"]]),
      .groups = "drop"
    )

  res <-
    data_metric_values |>
    dplyr::left_join(
      data_coverage,
      by = "repeat_id",
      relationship = "one-to-one"
    ) |>
    dplyr::transmute(
      repetition_id = .data[["repeat_id"]],
      spatial_mev_strategy = spatial_mev_strategy,
      mean_log_loss = .data[["log_loss"]],
      mean_auc = .data[["auc"]],
      mean_tjur_r2 = .data[["tjur_r2"]],
      evaluable_taxon_coverage =
        .data[["evaluable_taxon_coverage"]],
      technical_cv_status = technical_cv_status,
      assignment_hash = assignment_hash,
      artifact_schema_hash = artifact_schema_hash
    ) |>
    dplyr::arrange(.data[["repetition_id"]])

  assertthat::assert_that(
    base::nrow(res) > 0L,
    !base::anyNA(res),
    base::all(
      base::is.finite(
        base::as.matrix(
          res[
            base::c(
              "mean_log_loss",
              "mean_auc",
              "mean_tjur_r2",
              "evaluable_taxon_coverage"
            )
          ]
        )
      )
    ),
    msg = "Every benchmark repetition must have evaluable predictive metrics."
  )

  return(res)
}

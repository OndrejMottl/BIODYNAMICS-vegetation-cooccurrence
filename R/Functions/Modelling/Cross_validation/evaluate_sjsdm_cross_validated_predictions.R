#' @title Evaluate sjSDM Cross-Validated Predictions
#' @description
#' Pools selected-candidate out-of-fold predictions within each repeat and
#' taxon, then calculates taxon and community predictive metrics.
#' @param data_predictions
#' Long selected-candidate prediction table returned in the data-prediction
#' element of [run_sjsdm_selected_candidate_folds()].
#' @param epsilon
#' Probability clipping tolerance passed to
#' [evaluate_binary_log_loss()]. Defaults to 1e-6.
#' @return
#' Named list containing data_taxon_metrics and data_community_summary.
#' Taxon metrics have one row per repeat, taxon, and metric. Community
#' summaries contain the mean finite estimate across evaluable taxa for each
#' repeat and metric.
#' @details
#' Folds are pooled before metrics are calculated. Any non-ok prediction row
#' makes all metrics for that repeat and taxon incomplete. One-class pooled
#' responses retain the metric-specific undefined statuses from the binary
#' evaluators, while binary log loss remains evaluable.
#' @examples
#' \dontrun{
#' evaluate_sjsdm_cross_validated_predictions(
#'   data_predictions = data_predictions
#' )
#' }
#' @export
evaluate_sjsdm_cross_validated_predictions <- function(
    data_predictions = NULL,
    epsilon = 1e-6) {
  assertthat::assert_that(
    base::is.data.frame(data_predictions),
    base::nrow(data_predictions) > 0L,
    msg = "data_predictions must be a non-empty data frame."
  )

  vec_required_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "row_index",
      "taxon",
      "observed",
      "predicted_probability",
      "prediction_status"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_predictions)
    ),
    msg = "data_predictions is missing required columns."
  )

  flag_valid_epsilon <-
    base::is.numeric(epsilon) &&
    base::length(epsilon) == 1L &&
    base::is.finite(epsilon) &&
    epsilon > 0 &&
    epsilon < 0.5

  assertthat::assert_that(
    flag_valid_epsilon,
    msg = "epsilon must be one finite number between zero and 0.5."
  )

  assertthat::assert_that(
    base::is.numeric(data_predictions[["observed"]]),
    base::is.numeric(data_predictions[["predicted_probability"]]),
    base::is.character(data_predictions[["prediction_status"]]),
    msg = "Prediction values must be numeric and statuses character."
  )

  data_duplicate_keys <-
    data_predictions |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["row_index"]],
      .data[["taxon"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_keys) > 0L
  ) {
    cli::cli_abort(
      "Repeat, row, and taxon prediction keys must be unique."
    )
  }

  data_ok_predictions <-
    data_predictions |>
    dplyr::filter(.data[["prediction_status"]] == "ok")

  if (
    base::nrow(data_ok_predictions) > 0L &&
      (
        !base::all(base::is.finite(data_ok_predictions[["observed"]])) ||
          !base::all(
            base::is.finite(
              data_ok_predictions[["predicted_probability"]]
            )
          ) ||
          !base::all(
            data_ok_predictions[["observed"]] %in% base::c(0, 1)
          ) ||
          !base::all(
            data_ok_predictions[["predicted_probability"]] >= 0 &
              data_ok_predictions[["predicted_probability"]] <= 1
          )
      )
  ) {
    cli::cli_abort(
      "Rows with prediction status ok must contain valid binary predictions."
    )
  }

  data_group_keys <-
    data_predictions |>
    dplyr::distinct(.data[["repeat_id"]], .data[["taxon"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["taxon"]])

  data_taxon_metrics <-
    purrr::map2(
      .x = data_group_keys[["repeat_id"]],
      .y = data_group_keys[["taxon"]],
      .f = ~ {
        data_taxon_predictions <-
          data_predictions |>
          dplyr::filter(
            .data[["repeat_id"]] == .x,
            .data[["taxon"]] == .y
          ) |>
          dplyr::arrange(
            .data[["fold_id"]],
            .data[["row_index"]]
          )

        vec_observed <-
          data_taxon_predictions[["observed"]]

        vec_predicted_probability <-
          data_taxon_predictions[["predicted_probability"]]

        flag_complete <-
          base::all(
            data_taxon_predictions[["prediction_status"]] == "ok"
          )

        if (
          !flag_complete
        ) {
          vec_observed_available <-
            vec_observed[base::is.finite(vec_observed)]

          n_observations <-
            base::length(vec_observed_available)

          n_presences <-
            base::sum(vec_observed_available == 1)

          n_absences <-
            n_observations - n_presences

          prevalence <-
            if (
              n_observations > 0L
            ) {
              n_presences / n_observations
            } else {
              NA_real_
            }

          res_incomplete <-
            tibble::tibble(
              repeat_id = .x,
              taxon = .y,
              metric_id = base::c("tjur_r2", "auc", "log_loss"),
              estimate = NA_real_,
              metric_status = "incomplete_predictions",
              n_observations = base::as.integer(n_observations),
              n_presences = base::as.integer(n_presences),
              n_absences = base::as.integer(n_absences),
              prevalence = prevalence
            )

          return(res_incomplete)
        }

        data_tjur <-
          evaluate_tjur_r2(
            observed = vec_observed,
            predicted_probability = vec_predicted_probability
          ) |>
          dplyr::mutate(
            metric_id = "tjur_r2",
            estimate = .data[["tjur_r2"]]
          ) |>
          dplyr::select(
            "metric_id",
            "estimate",
            "metric_status",
            "n_observations",
            "n_presences",
            "n_absences",
            "prevalence"
          )

        data_auc <-
          evaluate_binary_auc(
            observed = vec_observed,
            predicted_probability = vec_predicted_probability
          ) |>
          dplyr::mutate(
            metric_id = "auc",
            estimate = .data[["auc"]]
          ) |>
          dplyr::select(
            "metric_id",
            "estimate",
            "metric_status",
            "n_observations",
            "n_presences",
            "n_absences",
            "prevalence"
          )

        data_log_loss <-
          evaluate_binary_log_loss(
            observed = vec_observed,
            predicted_probability = vec_predicted_probability,
            epsilon = epsilon
          ) |>
          dplyr::mutate(
            metric_id = "log_loss",
            estimate = .data[["log_loss"]]
          ) |>
          dplyr::select(
            "metric_id",
            "estimate",
            "metric_status",
            "n_observations",
            "n_presences",
            "n_absences",
            "prevalence"
          )

        res_complete <-
          base::list(data_tjur, data_auc, data_log_loss) |>
          purrr::list_rbind() |>
          dplyr::mutate(
            repeat_id = .x,
            taxon = .y,
            .before = 1L
          )

        return(res_complete)
      }
    ) |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["taxon"]],
      base::match(
        .data[["metric_id"]],
        base::c("tjur_r2", "auc", "log_loss")
      )
    )

  data_community_summary <-
    data_taxon_metrics |>
    dplyr::mutate(
      taxon_evaluable =
        .data[["metric_status"]] == "ok" &
        base::is.finite(.data[["estimate"]])
    ) |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["metric_id"]]
    ) |>
    dplyr::summarise(
      summary_statistic = "mean",
      n_taxa_evaluable = base::sum(.data[["taxon_evaluable"]]),
      estimate = dplyr::if_else(
        .data[["n_taxa_evaluable"]] > 0L,
        base::mean(
          .data[["estimate"]][.data[["taxon_evaluable"]]]
        ),
        NA_real_
      ),
      metric_status = dplyr::if_else(
        .data[["n_taxa_evaluable"]] > 0L,
        "ok",
        "undefined_no_evaluable_taxa"
      ),
      .groups = "drop"
    ) |>
    dplyr::select(
      "repeat_id",
      "metric_id",
      "summary_statistic",
      "estimate",
      "n_taxa_evaluable",
      "metric_status"
    ) |>
    dplyr::arrange(
      .data[["repeat_id"]],
      base::match(
        .data[["metric_id"]],
        base::c("tjur_r2", "auc", "log_loss")
      )
    )

  res <-
    base::list(
      data_taxon_metrics = data_taxon_metrics,
      data_community_summary = data_community_summary
    )

  return(res)
}

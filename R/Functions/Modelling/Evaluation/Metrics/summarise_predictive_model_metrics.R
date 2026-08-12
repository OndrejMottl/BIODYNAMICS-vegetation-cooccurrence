#' @title Summarise Predictive Model Metrics
#' @description
#' Averages successful community-level predictive metrics across repeats.
#' @param list_pooled_cv_evaluation
#' Cross-validated model-evaluation object, or `NULL`.
#' @return
#' A one-row tibble containing Tjur R2, AUC, and log-loss summaries.
#' @export
summarise_predictive_model_metrics <- function(
    list_pooled_cv_evaluation) {
  data_metric_template <-
    tibble::tibble(
      metric_id = base::c("tjur_r2", "auc", "log_loss"),
      metric_column = base::c(
        "predictive_tjur_r2_mean",
        "predictive_auc_mean",
        "predictive_log_loss_mean"
      )
    )

  data_metric_summary <-
    if (
      base::is.null(list_pooled_cv_evaluation) ||
        !("data_community_summary" %in%
          base::names(list_pooled_cv_evaluation))
    ) {
      tibble::tibble(
        metric_id = base::character(),
        estimate = base::numeric()
      )
    } else {
      data_community_summary <-
        list_pooled_cv_evaluation |>
        purrr::chuck("data_community_summary")

      if (
        !base::is.data.frame(data_community_summary) ||
          !base::all(
            base::c(
              "metric_id",
              "estimate",
              "metric_status"
            ) %in% base::colnames(data_community_summary)
          )
      ) {
        tibble::tibble(
          metric_id = base::character(),
          estimate = base::numeric()
        )
      } else {
        data_community_summary |>
          dplyr::filter(
            .data[["metric_status"]] == "ok",
            base::is.finite(.data[["estimate"]])
          ) |>
          dplyr::group_by(.data[["metric_id"]]) |>
          dplyr::summarise(
            estimate = base::mean(.data[["estimate"]]),
            .groups = "drop"
          )
      }
    }

  res <-
    data_metric_template |>
    dplyr::left_join(
      data_metric_summary,
      by = dplyr::join_by(metric_id),
      multiple = "error",
      unmatched = "drop"
    ) |>
    dplyr::select("metric_column", "estimate") |>
    tidyr::pivot_wider(
      names_from = "metric_column",
      values_from = "estimate"
    )

  return(res)
}

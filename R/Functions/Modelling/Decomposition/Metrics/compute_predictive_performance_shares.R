#' @title Compute Predictive Performance Decomposition Shares
#' @description
#' Converts full and reduced higher-is-better predictive metrics into
#' fold-level decomposition shares.
#' @param data_fold_metrics
#' Data frame with columns `repeat_id`, `fold_id`, `variant`, and the
#' metric named by `metric_column`. A `status` column is optional; when
#' present, only rows with status `"ok"` are used.
#' @param metric_column
#' Single character string. Name of the higher-is-better metric column.
#' @param metric_name
#' Single character string used in the output. Defaults to
#' `metric_column`.
#' @return
#' A tibble with one row per repeat, fold, and component.
#' @export
compute_predictive_performance_shares <- function(
    data_fold_metrics,
    metric_column,
    metric_name = metric_column) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_metrics),
    msg = "`data_fold_metrics` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(metric_column),
    base::length(metric_column) == 1L,
    base::nchar(metric_column) > 0L,
    msg = "`metric_column` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(metric_name),
    base::length(metric_name) == 1L,
    base::nchar(metric_name) > 0L,
    msg = "`metric_name` must be a single non-empty character string."
  )

  vec_required_cols <-
    base::c("repeat_id", "fold_id", "variant", metric_column)

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(data_fold_metrics)),
    msg = stringr::str_glue(
      "`data_fold_metrics` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
  )

  data_metrics <-
    data_fold_metrics |>
    dplyr::mutate(
      status = if (
        "status" %in% base::colnames(data_fold_metrics)
      ) {
        .data[["status"]]
      } else {
        "ok"
      }
    )

  res <-
    data_metrics |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["fold_id"]]
    ) |>
    dplyr::group_split(
      .keep = TRUE
    ) |>
    purrr::map(
      .f = ~ .compute_predictive_fold_shares(
        data_fold = .x,
        value_column = metric_column,
        direction = "higher",
        metric_name = metric_name
      )
    ) |>
    purrr::list_rbind()

  return(res)
}

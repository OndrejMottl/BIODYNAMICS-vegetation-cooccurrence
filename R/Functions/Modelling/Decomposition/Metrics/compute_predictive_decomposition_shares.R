#' @title Compute Predictive Decomposition Shares
#' @description
#' Converts full and reduced predictive losses into fold-level
#' decomposition shares for abiotic predictors, spatial predictors,
#' and species associations.
#' @param data_fold_metrics
#' Data frame with columns `repeat_id`, `fold_id`, `variant`, and
#' `loss`. A `status` column is optional; when present, only rows with
#' status `"ok"` are used.
#' @return
#' A tibble with one row per repeat, fold, and component.
#' @export
compute_predictive_decomposition_shares <- function(data_fold_metrics) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_metrics),
    msg = "`data_fold_metrics` must be a data frame."
  )

  vec_required_cols <-
    base::c("repeat_id", "fold_id", "variant", "loss")

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
        value_column = "loss",
        direction = "lower"
      )
    ) |>
    purrr::list_rbind()

  return(res)
}

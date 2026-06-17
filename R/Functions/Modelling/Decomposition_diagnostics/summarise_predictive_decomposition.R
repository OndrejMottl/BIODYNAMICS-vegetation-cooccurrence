#' @title Summarize Predictive Decomposition Shares
#' @description
#' Summarizes fold-level predictive decomposition shares with median and
#' 95 percent intervals.
#' @param data_shares
#' Data frame returned by `compute_predictive_decomposition_shares()`.
#' Must contain `component`, `share`, and `defined` columns.
#' @return
#' A tibble with one row per component.
#' @export
summarise_predictive_decomposition <- function(data_shares) {
  assertthat::assert_that(
    base::is.data.frame(data_shares),
    msg = "`data_shares` must be a data frame."
  )

  vec_required_cols <-
    c("component", "share", "defined")

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(data_shares)),
    msg = stringr::str_glue(
      "`data_shares` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
  )

  res <-
    data_shares |>
    dplyr::group_by(.data$component) |>
    dplyr::summarise(
      share_median = if (
        base::all(base::is.na(.data$share))
      ) {
        NA_real_
      } else {
        stats::median(.data$share, na.rm = TRUE)
      },
      lwr_95 = if (
        base::all(base::is.na(.data$share))
      ) {
        NA_real_
      } else {
        stats::quantile(
          x = .data$share,
          probs = 0.025,
          na.rm = TRUE,
          names = FALSE
        )
      },
      upr_95 = if (
        base::all(base::is.na(.data$share))
      ) {
        NA_real_
      } else {
        stats::quantile(
          x = .data$share,
          probs = 0.975,
          na.rm = TRUE,
          names = FALSE
        )
      },
      n_defined = base::sum(.data$defined, na.rm = TRUE),
      n_total = dplyr::n(),
      n_failed = dplyr::n() - base::sum(.data$defined, na.rm = TRUE),
      proportion_defined = base::sum(.data$defined, na.rm = TRUE) /
        dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$component)

  return(res)
}

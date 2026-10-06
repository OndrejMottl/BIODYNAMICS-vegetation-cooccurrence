#' @title Summarise Spatial Predictor-Inclusive Variance
#' @description
#' Summarises unit-level predictor-inclusive percentages for spatial variance
#' figures using medians and empirical 95 percent intervals.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()].
#' @return
#' A tibble with one row per scale, resolution, and predictor domain, including
#' `n_units`, `median`, `lwr_95`, and `upr_95`.
#' @export
summarise_spatial_predictor_inclusive_variance <- function(data_plot) {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    msg = "`data_plot` must be a data frame."
  )

  vec_required_columns <-
    base::c(
      "scale",
      "scale_id",
      "resolution_label",
      "component",
      "component_label",
      "component_total_percentage"
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_plot)),
    msg = stringr::str_glue(
      "`data_plot` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  res_data <-
    data_plot |>
    dplyr::group_by(
      .data$scale,
      .data$resolution_label,
      .data$component,
      .data$component_label
    ) |>
    dplyr::summarise(
      n_units = dplyr::n_distinct(.data$scale_id),
      median = if (
        base::all(base::is.na(.data$component_total_percentage))
      ) {
        NA_real_
      } else {
        stats::median(
          .data$component_total_percentage,
          na.rm = TRUE
        )
      },
      lwr_95 = if (
        base::all(base::is.na(.data$component_total_percentage))
      ) {
        NA_real_
      } else {
        stats::quantile(
          .data$component_total_percentage,
          probs = 0.025,
          na.rm = TRUE,
          names = FALSE
        )
      },
      upr_95 = if (
        base::all(base::is.na(.data$component_total_percentage))
      ) {
        NA_real_
      } else {
        stats::quantile(
          .data$component_total_percentage,
          probs = 0.975,
          na.rm = TRUE,
          names = FALSE
        )
      },
      .groups = "drop"
    )

  return(res_data)
}

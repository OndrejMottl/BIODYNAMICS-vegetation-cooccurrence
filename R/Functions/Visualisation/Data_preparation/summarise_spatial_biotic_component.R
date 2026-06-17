#' @title Summarise Spatial Biotic Component
#' @description
#' Summarises the Associations component for spatial variance spread
#' figures.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()].
#' @return
#' A tibble with median and 95 percent interval columns for the
#' biotic co-occurrence component.
#' @export
summarise_spatial_biotic_component <- function(data_plot) {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    msg = "`data_plot` must be a data frame."
  )

  vec_required_columns <-
    base::c(
      "scale",
      "resolution_label",
      "component",
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
    dplyr::filter(
      .data$component == "Associations"
    ) |>
    dplyr::group_by(
      .data$scale,
      .data$resolution_label
    ) |>
    dplyr::summarise(
      median = stats::median(
        .data$component_total_percentage,
        na.rm = TRUE
      ),
      lwr_95 = stats::quantile(
        .data$component_total_percentage,
        probs = 0.025,
        na.rm = TRUE,
        names = FALSE
      ),
      upr_95 = stats::quantile(
        .data$component_total_percentage,
        probs = 0.975,
        na.rm = TRUE,
        names = FALSE
      ),
      .groups = "drop"
    )

  return(res_data)
}

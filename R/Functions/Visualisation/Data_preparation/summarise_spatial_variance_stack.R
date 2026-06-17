#' @title Summarise Spatial Variance Stack
#' @description
#' Computes mean component percentages and an unexplained component for
#' stacked spatial variance-partitioning figures.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()].
#' @param vec_component_levels
#' Character vector giving the display order of variance components.
#' Must include `"Unexplained"`.
#' @return
#' A tibble with one row per scale, resolution label, and component
#' label.
#' @export
summarise_spatial_variance_stack <- function(
    data_plot,
    vec_component_levels) {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    msg = "`data_plot` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_component_levels) &&
      base::length(vec_component_levels) > 0L &&
      "Unexplained" %in% vec_component_levels,
    msg = "`vec_component_levels` must include `Unexplained`."
  )

  vec_required_columns <-
    base::c(
      "scale",
      "resolution_label",
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

  data_component_mean <-
    data_plot |>
    dplyr::group_by(
      .data$scale,
      .data$resolution_label,
      .data$component_label
    ) |>
    dplyr::summarise(
      component_total_percentage = base::mean(
        .data$component_total_percentage,
        na.rm = TRUE
      ),
      .groups = "drop"
    )

  data_unexplained <-
    data_component_mean |>
    dplyr::group_by(
      .data$scale,
      .data$resolution_label
    ) |>
    dplyr::summarise(
      component_total_percentage = base::pmax(
        0,
        100 - base::sum(
          .data$component_total_percentage,
          na.rm = TRUE
        )
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      component_label = "Unexplained"
    )

  res_data <-
    dplyr::bind_rows(
      data_component_mean,
      data_unexplained
    ) |>
    dplyr::mutate(
      component_label = base::factor(
        .data$component_label,
        levels = vec_component_levels
      )
    )

  return(res_data)
}

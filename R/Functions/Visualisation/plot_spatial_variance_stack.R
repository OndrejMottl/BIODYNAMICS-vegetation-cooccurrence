#' @title Plot Spatial Variance Stack
#' @description
#' Builds a stacked mean variance-partitioning plot.
#' @param data_component_stack
#' Data frame returned by [summarise_spatial_variance_stack()].
#' @param plot_title
#' Single character string used as the plot title.
#' @param vec_component_colours
#' Named character vector mapping component labels to colours.
#' @return
#' A `ggplot` object.
#' @export
plot_spatial_variance_stack <- function(
    data_component_stack,
    plot_title,
    vec_component_colours) {
  assertthat::assert_that(
    base::is.data.frame(data_component_stack),
    msg = "`data_component_stack` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(plot_title) &&
      base::length(plot_title) == 1L,
    msg = "`plot_title` must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(vec_component_colours) &&
      !base::is.null(base::names(vec_component_colours)),
    msg = "`vec_component_colours` must be a named character vector."
  )

  res_plot <-
    data_component_stack |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = scale,
        y = component_total_percentage,
        fill = component_label
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(resolution_label),
      nrow = 1
    ) +
    ggplot2::scale_fill_manual(
      values = vec_component_colours,
      name = "Component"
    ) +
    ggplot2::labs(
      title = plot_title,
      x = NULL,
      y = "Mean variance contribution (%)"
    ) +
    ggplot2::theme_classic() +
    ggplot2::theme(
      legend.position = "top",
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
    ) +
    ggplot2::geom_col(
      colour = "white",
      linewidth = 0.2
    )

  return(res_plot)
}

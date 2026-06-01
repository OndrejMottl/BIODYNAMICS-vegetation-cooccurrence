#' @title Plot Spatial Biotic Component
#' @description
#' Builds a jitter and interval plot for the Associations component.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()].
#' @param data_biotic_summary
#' Data frame returned by [summarise_spatial_biotic_component()].
#' @param plot_title
#' Single character string used as the plot title.
#' @return
#' A `ggplot` object.
#' @export
plot_spatial_biotic_component <- function(
    data_plot,
    data_biotic_summary,
    plot_title) {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    msg = "`data_plot` must be a data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_biotic_summary),
    msg = "`data_biotic_summary` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(plot_title) &&
      base::length(plot_title) == 1L,
    msg = "`plot_title` must be a single character string."
  )

  res_plot <-
    data_plot |>
    dplyr::filter(
      .data$component == "Associations"
    ) |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = resolution_label,
        y = component_total_percentage
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(scale),
      nrow = 1
    ) +
    ggplot2::labs(
      title = plot_title,
      x = NULL,
      y = "Variance contribution (%)"
    ) +
    ggplot2::theme_classic() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
    ) +
    ggplot2::geom_jitter(
      width = 0.12,
      height = 0,
      alpha = 0.35,
      size = 1.4,
      colour = "grey45"
    ) +
    ggplot2::geom_pointrange(
      data = data_biotic_summary,
      mapping = ggplot2::aes(
        y = median,
        ymin = lwr_95,
        ymax = upr_95
      ),
      colour = "#1B9E77",
      linewidth = 0.7,
      size = 0.9
    )

  return(res_plot)
}

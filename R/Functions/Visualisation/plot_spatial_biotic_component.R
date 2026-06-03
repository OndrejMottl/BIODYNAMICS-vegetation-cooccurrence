#' @title Plot Spatial Biotic Component
#' @description
#' Builds a jitter and interval plot for the Associations component.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()].
#' @param data_biotic_summary
#' Data frame returned by [summarise_spatial_biotic_component()].
#' @param plot_title
#' Single character string used as the plot title.
#' @param vec_continent_shapes
#' Optional named numeric vector mapping `continent_id` values to
#' point shapes.
#' @return
#' A `ggplot` object.
#' @export
plot_spatial_biotic_component <- function(
    data_plot,
    data_biotic_summary,
  plot_title,
  vec_continent_shapes = NULL) {
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

  if (
    !base::is.null(vec_continent_shapes)
  ) {
    assertthat::assert_that(
      base::is.numeric(vec_continent_shapes) &&
        !base::is.null(base::names(vec_continent_shapes)),
      msg = "`vec_continent_shapes` must be a named vector."
    )

    assertthat::assert_that(
      "continent_id" %in% base::colnames(data_plot),
      msg = "`data_plot` must contain `continent_id` when using shapes."
    )
  }

  res_plot <-
    data_plot |>
    dplyr::filter(
      .data$component == "Associations"
    ) |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = scale,
        y = component_total_percentage
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(resolution_label),
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
    )

  if (
    !base::is.null(vec_continent_shapes)
  ) {
    res_plot <-
      res_plot +
      ggplot2::geom_jitter(
        mapping = ggplot2::aes(shape = .data$continent_id),
        width = 0.12,
        height = 0,
        alpha = 0.35,
        size = 1.4,
        colour = "grey45"
      ) +
      ggplot2::scale_shape_manual(
        values = vec_continent_shapes,
        name = "Continent"
      )
  } else {
    res_plot <-
      res_plot +
      ggplot2::geom_jitter(
        width = 0.12,
        height = 0,
        alpha = 0.35,
        size = 1.4,
        colour = "grey45"
      )
  }

  res_plot <-
    res_plot +
    ggplot2::geom_pointrange(
      data = data_biotic_summary,
      mapping = ggplot2::aes(
        y = median,
        ymin = lwr_95,
        ymax = upr_95
      ),
      colour = "#C792EA",
      linewidth = 0.7,
      size = 0.9
    )

  return(res_plot)
}

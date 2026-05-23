#' @title Plot Spatial Variance Waffle
#' @description
#' Builds a unit-level waffle plot for the Associations component.
#' @param data_waffle
#' Data frame returned by [prepare_spatial_variance_waffle_data()].
#' @param plot_title
#' Single character string used as the plot title.
#' @param vec_continent_shapes
#' Named integer vector mapping continent identifiers to point shapes.
#' @return
#' A `ggplot` object.
#' @export
plot_spatial_variance_waffle <- function(
    data_waffle,
    plot_title,
    vec_continent_shapes) {
  assertthat::assert_that(
    base::is.data.frame(data_waffle),
    msg = "`data_waffle` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(plot_title) &&
      base::length(plot_title) == 1L,
    msg = "`plot_title` must be a single character string."
  )

  assertthat::assert_that(
    base::is.numeric(vec_continent_shapes) &&
      !base::is.null(base::names(vec_continent_shapes)),
    msg = "`vec_continent_shapes` must be a named numeric vector."
  )

  res_plot <-
    data_waffle |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = tile_col,
        y = tile_row,
        fill = R2_Nagelkerke_percentage
      )
    ) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(resolution_label),
      cols = ggplot2::vars(scale),
      switch = "both"
    ) +
    ggplot2::scale_colour_identity(
      guide = "none"
    ) +
    ggplot2::scale_shape_manual(
      values = vec_continent_shapes,
      name = "Continent"
    ) +
    ggplot2::scale_fill_viridis_c(
      limits = base::c(0, 100),
      name = expression(R^2 ~ "Nagelkerke (%)"),
      na.value = "grey90",
      option = "D"
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = plot_title
    ) +
    ggplot2::theme_classic() +
    ggplot2::guides(
      fill = ggplot2::guide_colorbar(order = 1),
      shape = ggplot2::guide_legend(order = 2)
    ) +
    ggplot2::theme(
      legend.position = "top",
      legend.box = "vertical",
      legend.box.just = "left",
      strip.background = ggplot2::element_blank(),
      strip.text.y.right = ggplot2::element_text(angle = 0),
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.line = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    ) +
    ggplot2::geom_tile(
      colour = "white",
      linewidth = 0.33
    ) +
    ggplot2::geom_point(
      mapping = ggplot2::aes(
        shape = continent_id,
        colour = point_colour
      ),
      fill = NA,
      size = 2,
      stroke = 0.6
    )

  return(res_plot)
}

#' @title Build Spatial Unit Frame
#' @description
#' Builds one animation frame for the spatial units map, drawing world
#' polygons, fossil pollen points, and a highlighted bounding box.
#' @param data_unit
#' One-row tibble with columns `x_min`, `x_max`, `y_min`, and `y_max`.
#' @param data_points
#' Tibble with columns `coord_long` and `coord_lat`.
#' @param scale_label
#' Character scalar. Scale label shown in the upper-left corner.
#' @param data_world
#' World polygon tibble with columns `long`, `lat`, and `group`.
#' @param x_limits
#' Numeric vector of length 2. Longitudinal map extent.
#' @param y_limits
#' Numeric vector of length 2. Latitudinal map extent.
#' @param buffer_degrees
#' Numeric scalar. Buffer in degrees added around map limits.
#' @param vec_palette
#' Optional named character vector of ORACLE colours. If `NULL`,
#' colours are read with `get_oracle_palette_values()`.
#' @param font_family
#' Character scalar. Font family for all text elements.
#' @return
#' A `ggplot` object for one animation frame.
#' @export
build_spatial_unit_frame <- function(
    data_unit,
    data_points,
    scale_label,
    data_world,
    x_limits,
    y_limits,
    buffer_degrees,
    vec_palette = NULL,
    font_family = "VT323") {
  assertthat::assert_that(
    base::is.data.frame(data_unit),
    base::all(
      base::c("x_min", "x_max", "y_min", "y_max") %in%
        base::colnames(data_unit)
    ),
    msg = paste(
      "'data_unit' must contain columns",
      "'x_min', 'x_max', 'y_min', and 'y_max'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_points),
    base::all(
      base::c("coord_long", "coord_lat") %in%
        base::colnames(data_points)
    ),
    msg = paste(
      "'data_points' must contain columns",
      "'coord_long' and 'coord_lat'."
    )
  )

  assertthat::assert_that(
    base::is.character(scale_label),
    base::length(scale_label) == 1L,
    msg = "'scale_label' must be a single character value."
  )

  assertthat::assert_that(
    base::is.data.frame(data_world),
    base::all(
      base::c("long", "lat", "group") %in%
        base::colnames(data_world)
    ),
    msg = "'data_world' must contain columns 'long', 'lat', and 'group'."
  )

  assertthat::assert_that(
    base::is.numeric(x_limits),
    base::length(x_limits) == 2L,
    msg = "'x_limits' must be a numeric vector of length 2."
  )

  assertthat::assert_that(
    base::is.numeric(y_limits),
    base::length(y_limits) == 2L,
    msg = "'y_limits' must be a numeric vector of length 2."
  )

  assertthat::assert_that(
    base::is.numeric(buffer_degrees),
    base::length(buffer_degrees) == 1L,
    base::is.finite(buffer_degrees),
    buffer_degrees >= 0,
    msg = "'buffer_degrees' must be a single non-negative numeric value."
  )

  assertthat::assert_that(
    base::is.character(font_family),
    base::length(font_family) == 1L,
    msg = "'font_family' must be a single character value."
  )

  if (
    base::is.null(vec_palette)
  ) {
    vec_palette <-
      get_oracle_palette_values()
  }

  res_plot <-
    ggplot2::ggplot() +
    ggplot2::coord_quickmap(
      xlim = base::range(x_limits) + base::c(-1, 1) * buffer_degrees,
      ylim = base::range(y_limits) + base::c(-1, 1) * buffer_degrees,
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::scale_colour_identity() +
    ggview::canvas(
      width = 760,
      height = 760,
      units = "px",
      dpi = 300,
      bg = vec_palette[["background"]]
    ) +
    create_oracle_theme(
      base_family = font_family,
      base_size = 11
    ) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(
        fill = vec_palette[["background"]],
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = vec_palette[["background"]],
        colour = NA
      ),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = vec_palette[["border"]],
        linewidth = 0.12,
        linetype = "dotted"
      ),
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      legend.position = "none",
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    ) +
    ggplot2::geom_polygon(
      data = data_world,
      mapping = ggplot2::aes(
        x = .data$long,
        y = .data$lat,
        group = .data$group
      ),
      fill = vec_palette[["surface_alt"]],
      colour = vec_palette[["border"]],
      linewidth = 0.16,
      alpha = 0.82
    ) +
    ggplot2::geom_point(
      data = data_points,
      mapping = ggplot2::aes(
        x = .data$coord_long,
        y = .data$coord_lat
      ),
      colour = vec_palette[["phosphor"]],
      fill = vec_palette[["surface_alt"]],
      shape = 22,
      size = 1,
      stroke = 0.55,
      alpha = 0.95
    ) +
    ggplot2::geom_rect(
      data = data_unit,
      mapping = ggplot2::aes(
        xmin = .data$x_min,
        xmax = .data$x_max,
        ymin = .data$y_min,
        ymax = .data$y_max
      ),
      fill = NA,
      colour = vec_palette[["cyan"]],
      linewidth = 0.5,
      linetype = "dashed",
      alpha = 0.62
    ) +
    ggplot2::annotate(
      geom = "text",
      x = base::min(x_limits) + 2.0,
      y = base::max(y_limits) - 1.5,
      label = stringr::str_to_upper(scale_label),
      hjust = 0,
      vjust = 1,
      colour = vec_palette[["cyan"]],
      family = font_family,
      fontface = "bold",
      size = 3.3
    )

  return(res_plot)
}

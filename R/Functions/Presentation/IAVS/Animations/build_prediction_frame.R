#' @title Build Prediction Frame
#' @description
#' Builds one animation frame for the IAVS paleo prediction animation,
#' showing a spatial prediction grid optionally overlaid with observation
#' points.
#' @param data_frame
#' Tibble with columns `age`, `coord_long`, `coord_lat`, and the column
#' named by `value_column`.
#' @param age_value
#' Numeric scalar. Age slice to plot.
#' @param value_column
#' Character scalar. Name of the fill value column in `data_frame`.
#' @param subtitle_label
#' Character scalar. Plot subtitle.
#' @param fill_label
#' Character scalar. Legend title.
#' @param fill_limits
#' Numeric vector of length 2. Limits for the fill scale.
#' @param list_prediction_grid
#' Named list with `x_lim` and `y_lim` entries.
#' @param data_world
#' World polygon tibble with columns `long`, `lat`, and `group`.
#' @param grid_resolution
#' Numeric scalar. Tile width and height in degrees.
#' @param fill_trans
#' Scale transform passed to `ggplot2::scale_fill_gradientn()`.
#' @param fill_colors
#' Character vector of length >= 2. Fill gradient colours.
#' @param data_points
#' Optional tibble with `age`, `coord_long`, `coord_lat` for overlaid
#' observation points.
#' @param point_color
#' Character scalar. Colour for observation points.
#' @param metric_label
#' Optional character vector. Metrics appended as a caption.
#' @param vec_palette
#' Optional named character vector of ORACLE colours. If `NULL`,
#' colours are read with `get_oracle_palette_values()`.
#' @param font_family
#' Character scalar. Font family for all text elements.
#' @return
#' A `ggplot` object for one prediction frame.
#' @export
build_prediction_frame <- function(
    data_frame,
    age_value,
    value_column,
    subtitle_label,
    fill_label,
    fill_limits,
    list_prediction_grid,
    data_world,
    grid_resolution,
    fill_trans = scales::transform_identity(),
    fill_colors = c("black", "white"),
    data_points = NULL,
    point_color = "red",
    metric_label = NULL,
    vec_palette = NULL,
    font_family = "VT323") {
  assertthat::assert_that(
    base::is.data.frame(data_frame),
    base::all(
      base::c("age", "coord_long", "coord_lat") %in%
        base::colnames(data_frame)
    ),
    msg = paste(
      "'data_frame' must contain columns",
      "'age', 'coord_long', and 'coord_lat'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(age_value),
    base::length(age_value) == 1L,
    base::is.finite(age_value),
    msg = "'age_value' must be one finite numeric value."
  )

  assertthat::assert_that(
    base::is.character(value_column),
    base::length(value_column) == 1L,
    value_column %in% base::colnames(data_frame),
    msg = "'value_column' must be a column name present in 'data_frame'."
  )

  assertthat::assert_that(
    base::is.character(fill_colors),
    base::length(fill_colors) >= 2L,
    msg = "'fill_colors' must contain at least two colour values."
  )

  assertthat::assert_that(
    base::is.list(list_prediction_grid),
    base::all(
      base::c("x_lim", "y_lim") %in% base::names(list_prediction_grid)
    ),
    msg = paste(
      "'list_prediction_grid' must be a named list with",
      "'x_lim' and 'y_lim' entries."
    )
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
    base::is.numeric(grid_resolution),
    base::length(grid_resolution) == 1L,
    base::is.finite(grid_resolution),
    grid_resolution > 0,
    msg = "'grid_resolution' must be one positive finite numeric value."
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

  data_age <-
    data_frame |>
    dplyr::filter(
      .data$age == age_value
    )

  vec_metric_label <-
    metric_label[!base::is.na(metric_label)]
  vec_metric_label <-
    vec_metric_label[base::nzchar(vec_metric_label)]
  caption_text <-
    stringr::str_flatten(
      vec_metric_label,
      collapse = " | "
    )

  res_plot <-
    ggplot2::ggplot() +
    ggplot2::coord_quickmap(
      xlim = list_prediction_grid[["x_lim"]],
      ylim = list_prediction_grid[["y_lim"]],
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::scale_fill_gradientn(
      colours = fill_colors,
      limits = fill_limits,
      trans = fill_trans,
      name = fill_label,
      guide = ggplot2::guide_colorbar(
        nbin = 200,
        title.position = "top",
        title.hjust = 0.5,
        barwidth = grid::unit(0.5, "lines"),
        barheight = grid::unit(5, "lines")
      )
    ) +
    ggview::canvas(
      width = 800,
      height = 620,
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
      legend.position = "right",
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      legend.box.margin = ggplot2::margin(0, 0, 0, 0),
      legend.background = ggplot2::element_blank(),
      legend.box.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_rect(
        fill = vec_palette[["background"]],
        colour = NA
      ),
      legend.title = ggplot2::element_text(
        size = 8,
        family = font_family,
        colour = vec_palette[["cyan"]]
      ),
      legend.text = ggplot2::element_text(
        size = 7,
        family = font_family,
        colour = vec_palette[["phosphor"]]
      ),
      plot.title = ggplot2::element_text(
        colour = vec_palette[["phosphor"]],
        family = font_family,
        face = "bold"
      ),
      plot.subtitle = ggplot2::element_text(
        colour = vec_palette[["cyan"]],
        family = font_family
      ),
      plot.caption = ggplot2::element_text(
        colour = vec_palette[["phosphor"]],
        family = font_family,
        size = 8,
        hjust = 0,
        margin = ggplot2::margin(5, 0, 0, 0)
      ),
      plot.margin = ggplot2::margin(5, 5, 5, 5)
    ) +
    ggplot2::labs(
      title = format_age_label(age_value),
      subtitle = subtitle_label,
      caption = caption_text
    ) +
    ggplot2::geom_tile(
      data = data_age,
      mapping = ggplot2::aes(
        x = .data$coord_long,
        y = .data$coord_lat,
        fill = .data[[value_column]]
      ),
      width = grid_resolution,
      height = grid_resolution,
      alpha = 0.9
    ) +
    ggplot2::geom_polygon(
      data = data_world,
      mapping = ggplot2::aes(
        x = .data$long,
        y = .data$lat,
        group = .data$group
      ),
      fill = NA,
      colour = vec_palette[["border"]],
      linewidth = 0.14,
      alpha = 0.75
    )

  if (
    isFALSE(base::is.null(data_points))
  ) {
    data_points_age <-
      data_points |>
      dplyr::filter(
        .data$age == age_value
      ) |>
      tidyr::drop_na(
        "coord_long",
        "coord_lat"
      )

    res_plot <-
      res_plot +
      ggplot2::geom_point(
        data = data_points_age,
        mapping = ggplot2::aes(
          x = .data$coord_long,
          y = .data$coord_lat
        ),
        inherit.aes = FALSE,
        size = 0.5,
        shape = 4,
        colour = point_color,
        alpha = 0.5
      )
  }

  return(res_plot)
}

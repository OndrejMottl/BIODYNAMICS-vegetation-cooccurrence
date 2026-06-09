#' @title Plot Spatial Variance Waffle
#' @description
#' Builds a unit-level waffle plot using precomputed fill colours.
#' @param data_waffle
#' Data frame returned by [prepare_spatial_variance_waffle_data()].
#' @param plot_title
#' Single character string used as the plot title.
#' @param vec_continent_shapes
#' Named integer vector mapping continent identifiers to point shapes.
#' @param flag_show_fill_legend
#' Logical. If `TRUE`, shows a fill legend for base component colours.
#' @param vec_component_colours
#' Optional named character vector mapping component IDs to HEX colours.
#' Required when `flag_show_fill_legend = TRUE`.
#' @param vec_required_components
#' Character vector of component IDs shown in the optional fill legend.
#' @param fill_legend_style
#' Single character string specifying fill legend style when
#' `flag_show_fill_legend = TRUE`. One of `"swatch"` (default) or
#' `"triangle"`.
#' @return
#' A `ggplot` object.
#' @export
plot_spatial_variance_waffle <- function(
    data_waffle,
    plot_title,
    vec_continent_shapes,
    flag_show_fill_legend = FALSE,
    vec_component_colours = NULL,
    vec_required_components = base::c(
      "Abiotic",
      "Spatial",
      "Associations"
    ),
    fill_legend_style = base::c("swatch", "triangle")) {
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

  assertthat::assert_that(
    base::is.logical(flag_show_fill_legend) &&
      base::length(flag_show_fill_legend) == 1L,
    msg = "`flag_show_fill_legend` must be a single logical value."
  )

  assertthat::assert_that(
    base::is.character(vec_required_components) &&
      base::length(vec_required_components) > 0L,
    msg = "`vec_required_components` must be a non-empty character vector."
  )

  fill_legend_style <-
    base::match.arg(
      arg = fill_legend_style,
      choices = base::c("swatch", "triangle")
    )

  if (
    isTRUE(flag_show_fill_legend)
  ) {
    assertthat::assert_that(
      base::is.character(vec_component_colours) &&
        !base::is.null(base::names(vec_component_colours)),
      msg = paste0(
        "`vec_component_colours` must be a named character vector ",
        "when `flag_show_fill_legend = TRUE`."
      )
    )

    vec_missing_colours <-
      base::setdiff(
        vec_required_components,
        base::names(vec_component_colours)
      )

    assertthat::assert_that(
      base::length(vec_missing_colours) == 0L,
      msg = stringr::str_glue(
        "`vec_component_colours` is missing legend colours for: ",
        "{stringr::str_c(vec_missing_colours, collapse = ', ')}."
      )
    )
  }

  vec_required_columns <-
    base::c(
      "scale",
      "resolution_label",
      "tile_col",
      "tile_row",
      "continent_id",
      "tile_fill_colour",
      "point_colour"
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_waffle)),
    msg = stringr::str_glue(
      "`data_waffle` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  if (
    isTRUE(flag_show_fill_legend) &&
      base::identical(fill_legend_style, "swatch")
  ) {
    data_fill_legend <-
      tibble::tibble(
        component_label = vec_required_components,
        x = 0,
        y = 0
      )

    scale_fill_layer <-
      ggplot2::scale_fill_manual(
        name = "Component colour",
        values = vec_component_colours[vec_required_components],
        drop = FALSE,
        guide = ggplot2::guide_legend(
          order = 1,
          override.aes = base::list(
            shape = 22,
            size = 5,
            colour = "grey30",
            alpha = 1
          )
        )
      )

    shape_guide_layer <-
      ggplot2::guides(
        shape = ggplot2::guide_legend(order = 2)
      )
  } else if (
    isTRUE(flag_show_fill_legend) &&
      base::identical(fill_legend_style, "triangle")
  ) {
    assertthat::assert_that(
      base::length(vec_required_components) == 3L,
      msg = paste0(
        "`vec_required_components` must contain exactly 3 components ",
        "for `fill_legend_style = 'triangle'`."
      )
    )

    scale_fill_layer <-
      ggplot2::scale_fill_identity(
        guide = "none"
      )

    shape_guide_layer <-
      ggplot2::guides(
        shape = ggplot2::guide_legend(order = 1)
      )
  } else {
    scale_fill_layer <-
      ggplot2::scale_fill_identity(
        guide = "none"
      )

    shape_guide_layer <-
      ggplot2::guides(
        shape = ggplot2::guide_legend(order = 1)
      )
  }

  res_plot <-
    data_waffle |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$tile_col,
        y = .data$tile_row
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
    scale_fill_layer +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = plot_title
    ) +
    ggplot2::theme_classic() +
    shape_guide_layer +
    ggplot2::theme(
      legend.position = "bottom",
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
      fill = data_waffle$tile_fill_colour,
      colour = "white",
      linewidth = 0.33
    ) +
    ggplot2::geom_point(
      mapping = ggplot2::aes(
        shape = .data$continent_id,
        colour = .data$point_colour
      ),
      fill = NA,
      size = 2,
      stroke = 0.6
    )

  if (
    isTRUE(flag_show_fill_legend) &&
      base::identical(fill_legend_style, "swatch")
  ) {
    res_plot <-
      res_plot +
      ggplot2::geom_point(
        data = data_fill_legend,
        mapping = ggplot2::aes(
          x = .data$x,
          y = .data$y,
          fill = .data$component_label
        ),
        inherit.aes = FALSE,
        shape = 22,
        size = 0,
        alpha = 0,
        show.legend = TRUE
      )
  }

  if (
    isTRUE(flag_show_fill_legend) &&
      base::identical(fill_legend_style, "triangle")
  ) {
    plot_triangle_legend <-
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        vec_required_components = vec_required_components,
        vec_component_labels = vec_required_components,
        max_component_value = 100,
        component_step = 2,
        label_colour = "grey35",
        border_colour = "grey35",
        point_size = 2.3,
        label_size = 3.2,
        triangle_x_offset = 0.16
      )

    res_plot <-
      cowplot::plot_grid(
        res_plot,
        plot_triangle_legend,
        ncol = 2,
        rel_widths = base::c(1, 0.34),
        align = "h",
        axis = "tb"
      )
  }

  return(res_plot)
}

#' @title Plot Spatial Variance Waffle
#' @description
#' Builds a unit-level waffle plot using precomputed fill colours.
#' @param data_waffle
#' Data frame returned by [prepare_spatial_variance_waffle_data()].
#' @param plot_title
#' Single character string used as the plot title.
#' @param vec_continent_shapes
#' Named integer vector mapping continent identifiers to point shapes.
#' @param flag_show_shape_legend
#' Logical. If `TRUE`, shows the continent shape legend.
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
#' @param plot_theme
#' A `ggplot2` theme object used as the base plot theme.
#' @param facet_switch
#' Optional facet strip switch passed to [ggplot2::facet_grid()]. Use
#' `NULL`, `"x"`, `"y"`, or `"both"`.
#' @param tile_border_colour
#' Single character string used for waffle tile borders.
#' @param tile_linewidth
#' Numeric scalar giving waffle tile border width.
#' @param tile_alpha
#' Numeric scalar giving waffle tile alpha.
#' @param point_size
#' Numeric scalar giving continent point size.
#' @param point_stroke
#' Numeric scalar giving continent point stroke.
#' @param triangle_legend_arguments
#' Named list of optional arguments forwarded to
#' [plot_variance_component_triangle_legend()] when
#' `fill_legend_style = "triangle"`.
#' @param triangle_legend_rel_width
#' Numeric scalar giving the relative width of the triangle legend.
#' @return
#' A `ggplot` object.
#' @export
plot_spatial_variance_waffle <- function(
    data_waffle,
    plot_title,
    vec_continent_shapes,
    flag_show_shape_legend = TRUE,
    flag_show_fill_legend = FALSE,
    vec_component_colours = NULL,
    vec_required_components = base::c(
      "Abiotic",
      "Spatial",
      "Associations"
    ),
    fill_legend_style = base::c("swatch", "triangle"),
    plot_theme = ggplot2::theme_classic(),
    facet_switch = "both",
    tile_border_colour = "white",
    tile_linewidth = 0.33,
    tile_alpha = 1,
    point_size = 2,
    point_stroke = 0.6,
    triangle_legend_arguments = base::list(),
    triangle_legend_rel_width = 0.34) {
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
    base::is.logical(flag_show_shape_legend) &&
      base::length(flag_show_shape_legend) == 1L,
    msg = "`flag_show_shape_legend` must be a single logical value."
  )

  assertthat::assert_that(
    base::is.character(vec_required_components) &&
      base::length(vec_required_components) > 0L,
    msg = "`vec_required_components` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::inherits(plot_theme, "theme"),
    msg = "`plot_theme` must be a ggplot2 theme object."
  )

  assertthat::assert_that(
    base::is.null(facet_switch) ||
      (
        base::is.character(facet_switch) &&
          base::length(facet_switch) == 1L &&
          facet_switch %in% base::c("x", "y", "both")
      ),
    msg = "`facet_switch` must be NULL, 'x', 'y', or 'both'."
  )

  assertthat::assert_that(
    base::is.character(tile_border_colour) &&
      base::length(tile_border_colour) == 1L,
    msg = "`tile_border_colour` must be a single character string."
  )

  assertthat::assert_that(
    base::is.numeric(tile_linewidth) &&
      base::length(tile_linewidth) == 1L &&
      base::is.finite(tile_linewidth) &&
      tile_linewidth >= 0,
    msg = "`tile_linewidth` must be a non-negative numeric scalar."
  )

  assertthat::assert_that(
    base::is.numeric(tile_alpha) &&
      base::length(tile_alpha) == 1L &&
      base::is.finite(tile_alpha) &&
      tile_alpha >= 0 &&
      tile_alpha <= 1,
    msg = "`tile_alpha` must be a numeric scalar from 0 to 1."
  )

  assertthat::assert_that(
    base::is.numeric(point_size) &&
      base::length(point_size) == 1L &&
      base::is.finite(point_size) &&
      point_size >= 0,
    msg = "`point_size` must be a non-negative numeric scalar."
  )

  assertthat::assert_that(
    base::is.numeric(point_stroke) &&
      base::length(point_stroke) == 1L &&
      base::is.finite(point_stroke) &&
      point_stroke >= 0,
    msg = "`point_stroke` must be a non-negative numeric scalar."
  )

  assertthat::assert_that(
    base::is.list(triangle_legend_arguments),
    msg = "`triangle_legend_arguments` must be a list."
  )

  assertthat::assert_that(
    base::is.numeric(triangle_legend_rel_width) &&
      base::length(triangle_legend_rel_width) == 1L &&
      base::is.finite(triangle_legend_rel_width) &&
      triangle_legend_rel_width > 0,
    msg = "`triangle_legend_rel_width` must be a positive numeric scalar."
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
      if (
        isTRUE(flag_show_shape_legend)
      ) {
        ggplot2::guides(
          shape = ggplot2::guide_legend(order = 2)
        )
      } else {
        ggplot2::guides(shape = "none")
      }
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
      if (
        isTRUE(flag_show_shape_legend)
      ) {
        ggplot2::guides(
          shape = ggplot2::guide_legend(order = 1)
        )
      } else {
        ggplot2::guides(shape = "none")
      }
  } else {
    scale_fill_layer <-
      ggplot2::scale_fill_identity(
        guide = "none"
      )

    shape_guide_layer <-
      if (
        isTRUE(flag_show_shape_legend)
      ) {
        ggplot2::guides(
          shape = ggplot2::guide_legend(order = 1)
        )
      } else {
        ggplot2::guides(shape = "none")
      }
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
      switch = facet_switch
    ) +
    ggplot2::scale_colour_identity(
      guide = "none"
    ) +
    ggplot2::scale_shape_manual(
      values = vec_continent_shapes,
      name = "Continent",
      guide = if (
        isTRUE(flag_show_shape_legend)
      ) {
        "legend"
      } else {
        "none"
      }
    ) +
    scale_fill_layer +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = plot_title
    ) +
    plot_theme +
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
      fill = data_waffle[["tile_fill_colour"]],
      colour = tile_border_colour,
      linewidth = tile_linewidth,
      alpha = tile_alpha
    ) +
    ggplot2::geom_point(
      mapping = ggplot2::aes(
        shape = .data$continent_id,
        colour = .data$point_colour
      ),
      fill = NA,
      size = point_size,
      stroke = point_stroke
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
    list_triangle_legend_arguments <-
      utils::modifyList(
        x = base::list(
          vec_component_colours = vec_component_colours,
          vec_required_components = vec_required_components,
          vec_component_labels = vec_required_components,
          max_component_value = 100,
          component_step = 2,
          label_colour = "grey35",
          border_colour = "grey35",
          point_size = 2.3,
          label_size = 3.2,
          triangle_x_offset = 0.16,
          method = "perc_avg"
        ),
        val = triangle_legend_arguments
      )

    plot_triangle_legend <-
      base::do.call(
        what = plot_variance_component_triangle_legend,
        args = list_triangle_legend_arguments
      )

    res_plot <-
      cowplot::plot_grid(
        res_plot,
        plot_triangle_legend,
        ncol = 2,
        rel_widths = base::c(1, triangle_legend_rel_width),
        align = "h",
        axis = "tb"
      )
  }

  return(res_plot)
}

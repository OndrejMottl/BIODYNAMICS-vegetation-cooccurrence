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
    value_triangle_side <-
      base::sqrt(3) / 2

    value_triangle_x_offset <- 0.16

    data_triangle_shares <-
      tidyr::expand_grid(
        share_1 = base::seq(0, 100, by = 2),
        share_2 = base::seq(0, 100, by = 2)
      ) |>
      dplyr::mutate(
        share_3 = 100 - .data$share_1 - .data$share_2
      ) |>
      dplyr::filter(
        .data$share_3 >= 0
      ) |>
      dplyr::mutate(
        observation_id = base::as.character(dplyr::row_number()),
        legend_x =
          .data$share_2 / 100 +
          .data$share_3 / 200 +
          value_triangle_x_offset,
        legend_y = .data$share_3 / 100 * value_triangle_side
      )

    data_triangle_components <-
      dplyr::bind_rows(
        data_triangle_shares |>
          dplyr::transmute(
            observation_id = .data$observation_id,
            component = vec_required_components[[1]],
            component_share = .data$share_1
          ),
        data_triangle_shares |>
          dplyr::transmute(
            observation_id = .data$observation_id,
            component = vec_required_components[[2]],
            component_share = .data$share_2
          ),
        data_triangle_shares |>
          dplyr::transmute(
            observation_id = .data$observation_id,
            component = vec_required_components[[3]],
            component_share = .data$share_3
          )
      )

    data_triangle_colours <-
      mix_variance_component_colours(
        data_component_shares = data_triangle_components,
        vec_component_colours = vec_component_colours,
        vec_required_components = vec_required_components,
        observation_id_column = "observation_id",
        component_column = "component",
        share_column = "component_share"
      )

    data_triangle_plot <-
      data_triangle_shares |>
      dplyr::left_join(
        y = data_triangle_colours,
        by = "observation_id"
      )

    plot_triangle_legend <-
      ggplot2::ggplot(
        data = data_triangle_plot,
        mapping = ggplot2::aes(
          x = .data$legend_x,
          y = .data$legend_y,
          fill = .data$tile_fill_colour
        )
      ) +
      ggplot2::geom_point(
        shape = 22,
        size = 2.3,
        stroke = 0
      ) +
      ggplot2::annotate(
        geom = "path",
        x = base::c(
          0,
          1,
          0.5,
          0
        ) + value_triangle_x_offset,
        y = base::c(0, 0, value_triangle_side, 0),
        linewidth = 0.3,
        colour = "grey35"
      ) +
      ggplot2::annotate(
        geom = "text",
        x = -0.08 + value_triangle_x_offset,
        y = -0.07,
        label = vec_required_components[[1]],
        hjust = 0,
        vjust = 1,
        size = 3.2
      ) +
      ggplot2::annotate(
        geom = "text",
        x = 1.08 + value_triangle_x_offset,
        y = -0.07,
        label = vec_required_components[[2]],
        hjust = 1,
        vjust = 1,
        size = 3.2
      ) +
      ggplot2::annotate(
        geom = "text",
        x = 0.5 + value_triangle_x_offset,
        y = value_triangle_side + 0.08,
        label = vec_required_components[[3]],
        hjust = 0.5,
        vjust = 0,
        size = 3.2
      ) +
      ggplot2::scale_fill_identity() +
      ggplot2::coord_equal(
        xlim = base::c(-0.02, 1.38),
        ylim = base::c(-0.14, value_triangle_side + 0.16),
        expand = FALSE,
        clip = "off"
      ) +
      ggplot2::theme_void() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(
          hjust = 0,
          size = 10
        ),
        plot.margin = ggplot2::margin(
          t = 6,
          r = 6,
          b = 6,
          l = 6
        )
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

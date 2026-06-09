#' @title Plot Variance Component Triangle Legend
#' @description
#' Draws a ternary colour legend for three variance components. Each
#' triangle corner represents the maximum value for one component, and
#' interior points are coloured by the blended component shares.
#' @param vec_component_colours
#' Named character vector mapping component IDs to HEX colours.
#' @param vec_required_components
#' Character vector with exactly three component IDs. These IDs are used
#' to read colours from `vec_component_colours`.
#' @param vec_component_labels
#' Character vector with exactly three display labels. Defaults to
#' `vec_required_components`.
#' @param max_component_value
#' Numeric scalar giving the value represented at each triangle corner.
#' Defaults to `100`.
#' @param component_step
#' Numeric scalar giving the grid step used to fill the triangle.
#' @param plot_title
#' Optional character scalar shown as the plot title.
#' @param font_family
#' Optional character scalar giving the font family for labels.
#' @param label_colour
#' Character vector giving the corner-label colour. Must have length
#' `1` for one shared colour or length `3` for one colour per label.
#' If length `3` and named, names are matched to
#' `vec_required_components`; otherwise colours are used in order.
#' @param title_colour
#' Character scalar giving the title colour.
#' @param border_colour
#' Character scalar giving the triangle-border colour.
#' @param background_colour
#' Character scalar giving the plot background colour.
#' @param point_size
#' Numeric scalar giving the size of interior colour points.
#' @param label_size
#' Numeric scalar giving the size of corner labels.
#' @param title_size
#' Numeric scalar giving the size of the optional title.
#' @param triangle_x_offset
#' Numeric scalar shifting the triangle horizontally.
#' @param method
#' Character string selecting the colour-mixing method passed to
#' [mix_variance_component_colours()].
#' @return
#' A `ggplot` object.
#' @export
plot_variance_component_triangle_legend <- function(
    vec_component_colours,
    vec_required_components = base::c(
      "Abiotic",
      "Spatial",
      "Associations"
    ),
    vec_component_labels = vec_required_components,
    max_component_value = 100,
    component_step = 2,
    plot_title = NULL,
    font_family = NULL,
    label_colour = "grey35",
    title_colour = label_colour,
    border_colour = "grey35",
    background_colour = "transparent",
    point_size = 2.3,
    label_size = 3.2,
    title_size = 10,
    triangle_x_offset = 0.16,
    method = base::c("perc_avg", "HCL")) {
  assertthat::assert_that(
    base::is.character(vec_component_colours) &&
      !base::is.null(base::names(vec_component_colours)),
    msg = "`vec_component_colours` must be a named character vector."
  )

  assertthat::assert_that(
    base::is.character(vec_required_components) &&
      base::length(vec_required_components) == 3L,
    msg = "`vec_required_components` must contain exactly 3 components."
  )

  assertthat::assert_that(
    base::is.character(vec_component_labels) &&
      base::length(vec_component_labels) == 3L,
    msg = "`vec_component_labels` must contain exactly 3 labels."
  )

  assertthat::assert_that(
    base::is.numeric(max_component_value) &&
      base::length(max_component_value) == 1L &&
      base::is.finite(max_component_value) &&
      max_component_value > 0,
    msg = "`max_component_value` must be a positive numeric scalar."
  )

  assertthat::assert_that(
    base::is.numeric(component_step) &&
      base::length(component_step) == 1L &&
      base::is.finite(component_step) &&
      component_step > 0 &&
      component_step <= max_component_value,
    msg = "`component_step` must be a positive numeric scalar."
  )

  if (
    !base::is.null(plot_title)
  ) {
    assertthat::assert_that(
      base::is.character(plot_title) &&
        base::length(plot_title) == 1L,
      msg = "`plot_title` must be NULL or a single character string."
    )
  }

  if (
    base::is.null(font_family)
  ) {
    font_family <- ""
  }

  assertthat::assert_that(
    base::is.character(font_family) &&
      base::length(font_family) == 1L,
    msg = "`font_family` must be NULL or a single character string."
  )

  assertthat::assert_that(
    base::is.character(label_colour) &&
      base::length(label_colour) %in% base::c(1L, 3L),
    msg = "`label_colour` must be a character vector of length 1 or 3."
  )

  if (
    base::length(label_colour) == 3L &&
      !base::is.null(base::names(label_colour))
  ) {
    vec_missing_label_colours <-
      base::setdiff(vec_required_components, base::names(label_colour))

    assertthat::assert_that(
      base::length(vec_missing_label_colours) == 0L,
      msg = stringr::str_glue(
        "`label_colour` is missing colours for: ",
        "{stringr::str_c(vec_missing_label_colours, collapse = ', ')}."
      )
    )

    label_colour <-
      base::unname(label_colour[vec_required_components])
  }

  vec_label_colours <-
    base::rep(
      x = label_colour,
      length.out = 3L
    )

  if (
    base::missing(title_colour) &&
      base::length(label_colour) == 3L
  ) {
    title_colour <- vec_label_colours[[3]]
  }

  assertthat::assert_that(
    base::is.character(title_colour) &&
      base::length(title_colour) == 1L,
    msg = "`title_colour` must be a single character string."
  )

  vec_allowed_methods <-
    base::c("HCL", "perc_avg")

  if (
    base::identical(method, vec_allowed_methods)
  ) {
    method <- "HCL"
  }

  assertthat::assert_that(
    base::is.character(method) &&
      base::length(method) == 1L &&
      method %in% vec_allowed_methods,
    msg = "`method` must be one of 'HCL' or 'perc_avg'."
  )

  vec_missing_colours <-
    base::setdiff(vec_required_components, base::names(vec_component_colours))

  assertthat::assert_that(
    base::length(vec_missing_colours) == 0L,
    msg = stringr::str_glue(
      "`vec_component_colours` is missing colours for: ",
      "{stringr::str_c(vec_missing_colours, collapse = ', ')}."
    )
  )

  value_triangle_side <-
    base::sqrt(3) / 2

  data_triangle_shares <-
    tidyr::expand_grid(
      component_1 = base::seq(
        from = 0,
        to = max_component_value,
        by = component_step
      ),
      component_2 = base::seq(
        from = 0,
        to = max_component_value,
        by = component_step
      )
    ) |>
    dplyr::mutate(
      component_3 =
        max_component_value - .data$component_1 - .data$component_2
    ) |>
    dplyr::filter(
      .data$component_3 >= 0
    ) |>
    dplyr::mutate(
      observation_id = base::as.character(dplyr::row_number()),
      legend_x =
        .data$component_2 / max_component_value +
        .data$component_3 / (2 * max_component_value) +
        triangle_x_offset,
      legend_y =
        .data$component_3 / max_component_value * value_triangle_side
    )

  data_triangle_components <-
    dplyr::bind_rows(
      data_triangle_shares |>
        dplyr::mutate(
          component = vec_required_components[[1]],
          component_share = .data$component_1 / max_component_value * 100
        ) |>
        dplyr::select(
          "observation_id",
          "component",
          "component_share"
        ),
      data_triangle_shares |>
        dplyr::mutate(
          component = vec_required_components[[2]],
          component_share = .data$component_2 / max_component_value * 100
        ) |>
        dplyr::select(
          "observation_id",
          "component",
          "component_share"
        ),
      data_triangle_shares |>
        dplyr::mutate(
          component = vec_required_components[[3]],
          component_share = .data$component_3 / max_component_value * 100
        ) |>
        dplyr::select(
          "observation_id",
          "component",
          "component_share"
        )
    )

  data_triangle_colours <-
    mix_variance_component_colours(
      data_component_shares = data_triangle_components,
      vec_component_colours = vec_component_colours,
      vec_required_components = vec_required_components,
      observation_id_column = "observation_id",
      component_column = "component",
      share_column = "component_share",
      method = method
    )

  data_triangle_plot <-
    data_triangle_shares |>
    dplyr::left_join(
      y = data_triangle_colours,
      by = dplyr::join_by(observation_id)
    )

  res_plot <-
    data_triangle_plot |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$legend_x,
        y = .data$legend_y,
        fill = .data$tile_fill_colour
      )
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::coord_equal(
      xlim = base::c(-0.02, 1.38) + triangle_x_offset - 0.16,
      ylim = base::c(-0.14, value_triangle_side + 0.16),
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::labs(
      title = plot_title
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        hjust = 0.5,
        colour = title_colour,
        family = font_family,
        size = title_size
      ),
      plot.background = ggplot2::element_rect(
        fill = background_colour,
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = background_colour,
        colour = NA
      ),
      plot.margin = ggplot2::margin(
        t = 6,
        r = 6,
        b = 6,
        l = 6
      )
    ) +
    ggplot2::geom_point(
      shape = 22,
      size = point_size,
      stroke = 0
    ) +
    ggplot2::annotate(
      geom = "path",
      x = base::c(
        0,
        1,
        0.5,
        0
      ) + triangle_x_offset,
      y = base::c(0, 0, value_triangle_side, 0),
      linewidth = 0.3,
      colour = border_colour
    ) +
    ggplot2::annotate(
      geom = "text",
      x = -0.08 + triangle_x_offset,
      y = -0.07,
      label = vec_component_labels[[1]],
      hjust = 0,
      vjust = 1,
      colour = vec_label_colours[[1]],
      family = font_family,
      size = label_size
    ) +
    ggplot2::annotate(
      geom = "text",
      x = 1.08 + triangle_x_offset,
      y = -0.07,
      label = vec_component_labels[[2]],
      hjust = 1,
      vjust = 1,
      colour = vec_label_colours[[2]],
      family = font_family,
      size = label_size
    ) +
    ggplot2::annotate(
      geom = "text",
      x = 0.5 + triangle_x_offset,
      y = value_triangle_side + 0.08,
      label = vec_component_labels[[3]],
      hjust = 0.5,
      vjust = 0,
      colour = vec_label_colours[[3]],
      family = font_family,
      size = label_size
    )

  return(res_plot)
}

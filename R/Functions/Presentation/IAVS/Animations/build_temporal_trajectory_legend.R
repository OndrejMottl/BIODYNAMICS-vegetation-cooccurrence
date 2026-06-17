#' @title Build Temporal Trajectory Legend
#' @description
#' Builds the static legend panel for the IAVS temporal ANOVA component
#' animation, showing component colour swatches and the modularity Q line.
#' @param vec_required_components
#' Character vector of component names in display order.
#' @param vec_component_labels
#' Named character vector mapping component names to display labels.
#' @param vec_component_colours
#' Named character vector mapping component names to fill colours.
#' @param colour_modularity
#' Character scalar. Colour for the modularity Q legend swatch.
#' @param vec_palette
#' Optional named character vector of ORACLE colours. If `NULL`,
#' colours are read with `get_oracle_palette_values()`.
#' @param font_family
#' Character scalar. Font family for all text elements.
#' @return
#' A `ggplot` legend panel.
#' @export
build_temporal_trajectory_legend <- function(
    vec_required_components,
    vec_component_labels,
    vec_component_colours,
    colour_modularity,
    vec_palette = NULL,
    font_family = "VT323") {
  assertthat::assert_that(
    base::is.character(vec_required_components),
    base::length(vec_required_components) >= 1L,
    msg = paste(
      "'vec_required_components' must be a non-empty character vector."
    )
  )

  assertthat::assert_that(
    base::is.character(vec_component_labels),
    base::all(
      vec_required_components %in% base::names(vec_component_labels)
    ),
    msg = paste(
      "'vec_component_labels' must be a named vector containing",
      "all values in 'vec_required_components'."
    )
  )

  assertthat::assert_that(
    base::is.character(vec_component_colours),
    base::all(
      vec_required_components %in% base::names(vec_component_colours)
    ),
    msg = paste(
      "'vec_component_colours' must be a named vector containing",
      "all values in 'vec_required_components'."
    )
  )

  assertthat::assert_that(
    base::is.character(colour_modularity),
    base::length(colour_modularity) == 1L,
    msg = "'colour_modularity' must be a single character value."
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

  data_legend <-
    tibble::tibble(
      component = base::factor(
        vec_required_components,
        levels = vec_required_components
      ),
      label = base::unname(
        vec_component_labels[vec_required_components]
      ),
      fill_colour = base::unname(
        vec_component_colours[vec_required_components]
      ),
      y = base::rev(base::seq_along(vec_required_components))
    )

  data_modularity_legend <-
    tibble::tibble(
      label = "Modularity Q",
      y = 1
    )

  res_plot <-
    ggplot2::ggplot() +
    ggplot2::coord_cartesian(
      xlim = base::c(0, 340),
      ylim = base::c(0, 800),
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_colour_identity() +
    create_oracle_theme(
      base_family = font_family,
      base_size = 10
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
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      legend.position = "none",
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    ) +
    ggview::canvas(
      width = 380,
      height = 800,
      units = "px",
      dpi = 300,
      bg = vec_palette[["background"]]
    ) +
    ggplot2::geom_rect(
      mapping = ggplot2::aes(
        xmin = 12,
        xmax = 328,
        ymin = 235,
        ymax = 485
      ),
      fill = vec_palette[["background"]],
      colour = vec_palette[["border"]],
      linewidth = 0.5
    ) +
    ggplot2::geom_text(
      mapping = ggplot2::aes(
        x = 36,
        y = 452,
        label = "SIGNAL"
      ),
      hjust = 0,
      colour = vec_palette[["muted"]],
      family = font_family,
      fontface = "bold",
      size = 3.6
    ) +
    ggplot2::geom_rect(
      data = data_legend,
      mapping = ggplot2::aes(
        xmin = 36,
        xmax = 84,
        ymin = 266 + (.data$y - 1) * 42,
        ymax = 294 + (.data$y - 1) * 42,
        fill = .data$fill_colour
      ),
      colour = vec_palette[["background"]],
      linewidth = 0.35
    ) +
    ggplot2::geom_text(
      data = data_legend,
      mapping = ggplot2::aes(
        x = 102,
        y = 280 + (.data$y - 1) * 42,
        label = .data$label
      ),
      hjust = 0,
      vjust = 0.5,
      colour = vec_palette[["text"]],
      family = font_family,
      size = 3.4
    ) +
    ggplot2::geom_segment(
      data = data_modularity_legend,
      mapping = ggplot2::aes(
        x = 36,
        xend = 84,
        y = 418,
        yend = 418
      ),
      colour = colour_modularity,
      linetype = "solid",
      linewidth = 1.1
    ) +
    ggplot2::geom_text(
      data = data_modularity_legend,
      mapping = ggplot2::aes(
        x = 102,
        y = 418,
        label = .data$label
      ),
      hjust = 0,
      vjust = 0.5,
      colour = vec_palette[["text"]],
      family = font_family,
      size = 3.4
    )

  return(res_plot)
}

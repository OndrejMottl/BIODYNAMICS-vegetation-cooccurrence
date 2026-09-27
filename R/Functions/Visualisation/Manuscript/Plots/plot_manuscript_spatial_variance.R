#' @title Plot Manuscript Spatial Variance Partitioning
#' @description
#' Builds the shared two-panel variance-partitioning figure used for paleo and
#' modern results: normalized component composition and unit-level association
#' spread with median and 95 percent interval.
#' @param data_plot Prepared unit-level spatial variance data.
#' @param data_component_summary Grouped component-composition data.
#' @param data_biotic_summary Grouped association summary data.
#' @return A `cowplot` assembled plot object.
#' @export
plot_manuscript_spatial_variance <- function(
    data_plot,
    data_component_summary,
    data_biotic_summary) {
  validate_manuscript_plot_data(
    data_plot = data_plot,
    required_columns = base::c(
      "scale",
      "scale_id",
      "resolution_label",
      "component",
      "component_total_percentage",
      "continent_id"
    ),
    numeric_bounds = base::list(
      component_total_percentage = base::c(0, 100)
    )
  )
  validate_manuscript_plot_data(
    data_plot = data_component_summary,
    required_columns = base::c(
      "scale",
      "resolution_label",
      "component_label",
      "component_total_percentage"
    ),
    numeric_bounds = base::list(
      component_total_percentage = base::c(0, 100)
    )
  )
  validate_manuscript_plot_data(
    data_plot = data_biotic_summary,
    required_columns = base::c(
      "scale",
      "resolution_label",
      "median",
      "lwr_95",
      "upr_95"
    ),
    numeric_bounds = base::list(
      median = base::c(0, 100),
      lwr_95 = base::c(0, 100),
      upr_95 = base::c(0, 100)
    )
  )

  vec_component_colours <-
    build_manuscript_palette("variance_component")
  vec_continent_colours <-
    build_manuscript_palette("continent")
  vec_continent_shapes <-
    base::c(america = 21, europe = 22, asia = 24)

  plot_composition <-
    data_component_summary |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$scale,
        y = .data$component_total_percentage,
        fill = .data$component_label
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$resolution_label),
      nrow = 1L
    ) +
    ggplot2::scale_y_continuous(
      limits = base::c(0, 100),
      breaks = base::seq(0, 100, by = 25),
      labels = scales::label_number(suffix = "%"),
      expand = ggplot2::expansion(mult = base::c(0, 0))
    ) +
    ggplot2::scale_fill_manual(
      values = vec_component_colours,
      name = "Variance component",
      drop = FALSE
    ) +
    ggplot2::labs(
      x = NULL,
      y = "Mean variance contribution"
    ) +
    build_manuscript_theme() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      legend.position = "top"
    ) +
    ggplot2::geom_col(
      width = 0.72,
      colour = "white",
      linewidth = 0.2
    )

  plot_associations <-
    data_plot |>
    dplyr::filter(.data$component == "Associations") |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$scale,
        y = .data$component_total_percentage
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$resolution_label),
      nrow = 1L
    ) +
    ggplot2::scale_y_continuous(
      limits = base::c(0, 100),
      breaks = base::seq(0, 100, by = 25),
      labels = scales::label_number(suffix = "%")
    ) +
    ggplot2::scale_fill_manual(
      values = vec_continent_colours,
      name = "Continent"
    ) +
    ggplot2::scale_shape_manual(
      values = vec_continent_shapes,
      name = "Continent"
    ) +
    ggplot2::labs(
      x = "Spatial tier",
      y = "Association variance"
    ) +
    build_manuscript_theme() +
    ggplot2::theme(
      panel.grid.major.x = ggplot2::element_blank(),
      legend.position = "top"
    ) +
    ggplot2::geom_jitter(
      mapping = ggplot2::aes(
        fill = .data$continent_id,
        shape = .data$continent_id
      ),
      position = ggplot2::position_jitter(
        width = 0.12,
        height = 0,
        seed = 900723
      ),
      colour = "white",
      stroke = 0.25,
      size = 1.35,
      alpha = 0.65
    ) +
    ggplot2::geom_linerange(
      data = data_biotic_summary,
      mapping = ggplot2::aes(
        x = .data$scale,
        ymin = .data$lwr_95,
        ymax = .data$upr_95
      ),
      colour = "grey10",
      linewidth = 0.7,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_point(
      data = data_biotic_summary,
      mapping = ggplot2::aes(
        x = .data$scale,
        y = .data$median
      ),
      shape = 95,
      size = 5.5,
      colour = "grey10",
      inherit.aes = FALSE
    )

  res_plot <-
    cowplot::plot_grid(
      plot_composition,
      plot_associations,
      labels = base::c("A", "B"),
      ncol = 1L,
      align = "v",
      rel_heights = base::c(1, 1.1)
    )

  return(res_plot)
}

#' @title Plot Manuscript Predictor-Inclusive Variance
#' @description
#' Builds the shared manuscript figure for overlapping predictor-inclusive
#' variance contributions across spatial tiers and taxonomic resolutions.
#' @param data_plot
#' Prepared unit-level predictor-inclusive variance data.
#' @param data_summary
#' Grouped median and empirical 95 percent interval data.
#' @return
#' A `ggplot` object with predictor domains in rows and resolutions in columns.
#' @export
plot_manuscript_predictor_inclusive_variance <- function(
    data_plot,
    data_summary) {
  validate_manuscript_plot_data(
    data_plot = data_plot,
    required_columns = base::c(
      "scale",
      "scale_id",
      "resolution_label",
      "component",
      "component_label",
      "component_total_percentage",
      "continent_id"
    ),
    numeric_bounds = base::list(
      component_total_percentage = base::c(0, 100)
    )
  )
  validate_manuscript_plot_data(
    data_plot = data_summary,
    required_columns = base::c(
      "scale",
      "resolution_label",
      "component",
      "component_label",
      "n_units",
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

  vec_continent_colours <-
    build_manuscript_palette(domain = "continent")
  vec_continent_shapes <-
    base::c(america = 21, europe = 22, asia = 24)

  res_plot <-
    data_plot |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$scale,
        y = .data$component_total_percentage
      )
    ) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(.data$component_label),
      cols = ggplot2::vars(.data$resolution_label),
      scales = "fixed"
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
      y = "Predictor-inclusive explained variation",
      caption = stringr::str_c(
        "Shared fractions contribute in full to every relevant predictor ",
        "domain; domain percentages overlap and need not sum to 100%."
      )
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
      data = data_summary,
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
      data = data_summary,
      mapping = ggplot2::aes(
        x = .data$scale,
        y = .data$median
      ),
      shape = 95,
      size = 5.5,
      colour = "grey10",
      inherit.aes = FALSE
    )

  return(res_plot)
}

#' @title Plot a Manuscript Spatial Association Atlas Panel
#' @description
#' Draws one continent and spatial-tier map. Each spatial unit contains a
#' horizontally ordered genus, family, and functional-type glyph so all
#' taxonomic resolutions remain comparable without separate map panels.
#' @param data_map Spatial association map data returned by
#' [prepare_spatial_association_map_data()].
#' @param sf_world World basemap as an sf object.
#' @param continent_id,scale_id Character identifiers selecting one panel.
#' @param resolution_ids Ordered character resolution identifiers.
#' @param panel_label Character scalar used as the compact panel title.
#' @return A ggplot object.
#' @export
plot_manuscript_spatial_map_panel <- function(
    data_map,
    sf_world,
    continent_id,
    scale_id,
    resolution_ids = base::c(
      "genus",
      "family",
      "functional_type"
    ),
    panel_label) {
  validate_manuscript_plot_data(
    data_plot = data_map,
    required_columns = base::c(
      "continent_id",
      "scale",
      "scale_id",
      "resolution_id",
      "x_min",
      "x_max",
      "y_min",
      "y_max",
      "glyph_x",
      "glyph_y",
      "association_percentage",
      "availability_status"
    )
  )
  assertthat::assert_that(
    base::inherits(sf_world, "sf"),
    msg = "sf_world must be an sf object."
  )
  assertthat::assert_that(
    base::is.character(resolution_ids),
    base::length(resolution_ids) > 0L,
    !base::any(base::is.na(resolution_ids)),
    !base::any(base::duplicated(resolution_ids)),
    msg = "resolution_ids must contain unique non-missing IDs."
  )

  vec_resolution_labels <-
    base::c(
      genus = "Genus",
      family = "Family",
      functional_type = "Functional type"
    )
  vec_resolution_shapes <-
    base::c(
      genus = 21,
      family = 22,
      functional_type = 24
    )
  assertthat::assert_that(
    base::all(resolution_ids %in% base::names(vec_resolution_shapes)),
    msg = "The atlas received an unsupported resolution identifier."
  )

  data_panel <-
    data_map |>
    dplyr::filter(
      .data$continent_id == .env$continent_id,
      .data$scale == .env$scale_id,
      .data$resolution_id %in% .env$resolution_ids
    ) |>
    dplyr::mutate(
      resolution_id = base::factor(
        .data$resolution_id,
        levels = .env$resolution_ids
      ),
      availability_status = base::factor(
        .data$availability_status,
        levels = base::c(
          "available",
          "expected_infeasible",
          "missing_model"
        )
      )
    )
  validate_manuscript_plot_data(
    data_plot = data_panel,
    required_columns = base::c(
      "scale_id",
      "resolution_id",
      "association_percentage",
      "availability_status"
    )
  )
  assertthat::assert_that(
    base::all(resolution_ids %in% data_panel$resolution_id),
    msg = "The atlas panel is missing an expected resolution."
  )

  data_extent <-
    data_map |>
    dplyr::filter(.data$continent_id == .env$continent_id) |>
    dplyr::summarise(
      x_min = base::min(.data$x_min),
      x_max = base::max(.data$x_max),
      y_min = base::min(.data$y_min),
      y_max = base::max(.data$y_max)
    )
  data_grid <-
    data_panel |>
    dplyr::distinct(
      .data$scale_id,
      .data$x_min,
      .data$x_max,
      .data$y_min,
      .data$y_max
    )
  data_available <-
    data_panel |>
    dplyr::filter(
      base::is.finite(.data$association_percentage)
    )
  data_unavailable <-
    data_panel |>
    dplyr::filter(
      !base::is.finite(.data$association_percentage)
    )
  data_missing <-
    data_unavailable |>
    dplyr::filter(
      base::as.character(.data$availability_status) == "missing_model"
    )

  point_size <-
    base::switch(
      scale_id,
      continental = 3.2,
      regional = 2,
      local = 1.1,
      1.5
    )
  grid_linewidth <-
    base::switch(
      scale_id,
      continental = 0.3,
      regional = 0.2,
      local = 0.08,
      0.2
    )
  grid_colour <-
    base::switch(
      scale_id,
      continental = "grey58",
      regional = "grey68",
      local = "grey82",
      "grey70"
    )
  n_available <- base::nrow(data_available)
  n_total <- base::nrow(data_panel)

  res_plot <-
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = sf_world,
      fill = "grey96",
      colour = "grey78",
      linewidth = 0.15,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_rect(
      data = data_grid,
      mapping = ggplot2::aes(
        xmin = .data$x_min,
        xmax = .data$x_max,
        ymin = .data$y_min,
        ymax = .data$y_max
      ),
      fill = NA,
      colour = grid_colour,
      linewidth = grid_linewidth
    ) +
    ggplot2::geom_point(
      data = data_available,
      mapping = ggplot2::aes(
        x = .data$glyph_x,
        y = .data$glyph_y,
        fill = .data$association_percentage,
        shape = .data$resolution_id
      ),
      size = point_size,
      stroke = 0.35,
      colour = "grey15"
    ) +
    ggplot2::scale_fill_viridis_c(
      option = "C",
      limits = base::c(0, 100),
      name = "Association variance (%)",
      na.value = "white"
    ) +
    ggplot2::scale_shape_manual(
      values = vec_resolution_shapes,
      breaks = resolution_ids,
      labels = base::unname(
        vec_resolution_labels[resolution_ids]
      ),
      name = "Resolution",
      drop = FALSE
    ) +
    ggplot2::guides(
      fill = ggplot2::guide_colourbar(
        order = 1,
        title.position = "top",
        barwidth = grid::unit(24, "mm"),
        barheight = grid::unit(2.5, "mm")
      ),
      shape = ggplot2::guide_legend(
        order = 2,
        title.position = "top",
        nrow = 1,
        override.aes = base::list(fill = "grey55")
      )
    ) +
    ggplot2::labs(
      title = panel_label,
      subtitle = stringr::str_glue(
        "{n_available}/{n_total} fitted"
      ),
      x = NULL,
      y = NULL
    ) +
    build_manuscript_theme(base_size = 8) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "plain",
        hjust = 0.5,
        margin = ggplot2::margin(b = 0.5)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = "grey35",
        hjust = 0.5,
        size = 6.5,
        margin = ggplot2::margin(b = 1)
      ),
      panel.grid = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.line = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.box.just = "center",
      legend.title = ggplot2::element_text(size = 7),
      legend.text = ggplot2::element_text(size = 6.5)
    ) +
    ggplot2::coord_sf(
      xlim = base::c(
        dplyr::pull(data_extent, .data$x_min),
        dplyr::pull(data_extent, .data$x_max)
      ),
      ylim = base::c(
        dplyr::pull(data_extent, .data$y_min),
        dplyr::pull(data_extent, .data$y_max)
      ),
      default_crs = sf::st_crs(4326),
      expand = FALSE
    )

  if (base::nrow(data_unavailable) > 0L) {
    res_plot <-
      res_plot +
      ggplot2::geom_point(
        data = data_unavailable,
        mapping = ggplot2::aes(
          x = .data$glyph_x,
          y = .data$glyph_y,
          shape = .data$resolution_id,
          colour = .data$availability_status
        ),
        size = point_size * 0.72,
        stroke = 0.3,
        fill = "white"
      ) +
      ggplot2::scale_colour_manual(
        values = base::c(
          expected_infeasible = "grey78",
          missing_model = "grey25"
        ),
        breaks = base::c(
          "expected_infeasible",
          "missing_model"
        ),
        labels = base::c(
          "Expected infeasible",
          "Missing model"
        ),
        name = "Unavailable",
        drop = FALSE
      ) +
      ggplot2::guides(
        colour = ggplot2::guide_legend(
          order = 3,
          title.position = "top",
          nrow = 1,
          override.aes = base::list(
            shape = 22,
            fill = "white"
          )
        )
      )
  }
  if (base::nrow(data_missing) > 0L) {
    res_plot <-
      res_plot +
      ggplot2::geom_point(
        data = data_missing,
        mapping = ggplot2::aes(
          x = .data$glyph_x,
          y = .data$glyph_y
        ),
        shape = 4,
        size = point_size * 0.45,
        stroke = 0.3,
        colour = "grey20"
      )
  }

  return(res_plot)
}

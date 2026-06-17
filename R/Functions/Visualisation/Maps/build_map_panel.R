#' @title Build one spatial ANOVA map panel
#' @description
#' Builds a single \code{ggplot2} map panel showing the
#' Shapley-adjusted percentage variance explained by
#' Associations for one combination of continent, spatial
#' scale, and taxonomic resolution. Grid rectangles are
#' coloured by association percentage (viridis gradient,
#' grey when no result). Fossil core locations are
#' overlaid as points when available.
#' @param sel_continent
#' Character scalar. Continent identifier
#' (e.g. \code{"europe"}, \code{"america"},
#' \code{"asia"}).
#' @param sel_scale
#' Character scalar. Spatial scale identifier
#' (e.g. \code{"continental"}, \code{"regional"},
#' \code{"local"}).
#' @param sel_resolution
#' Character scalar. Taxonomic resolution identifier
#' (e.g. \code{"genus"}, \code{"family"},
#' \code{"functional_type"}).
#' @param xlim_val
#' Numeric vector of length 2. Longitude limits for
#' \code{ggplot2::coord_sf()} (western, eastern).
#' @param ylim_val
#' Numeric vector of length 2. Latitude limits for
#' \code{ggplot2::coord_sf()} (southern, northern).
#' @param data_grid_with_results
#' Data frame. Spatial grid joined with ANOVA
#' association percentages; must contain columns
#' \code{continent}, \code{scale},
#' \code{taxonomic_resolution}, \code{x_min},
#' \code{x_max}, \code{y_min}, \code{y_max},
#' \code{assoc_pct}.
#' @param data_coords_per_unit
#' Data frame. Per-unit fossil core coordinates; must
#' contain columns \code{continent}, \code{scale},
#' \code{coords} (list-column of data frames with
#' \code{coord_long} and \code{coord_lat}).
#' @param sf_world
#' \code{sf} object. World polygon basemap used as the
#' background layer.
#' @param graphical_options
#' Named list of canvas settings (e.g. from
#' \code{get_active_config("graphical")}); must contain
#' \code{width}, \code{height}, \code{units},
#' \code{dpi}, \code{bg}.
#' @param show_x_axis
#' Logical scalar. When \code{FALSE}, x-axis text and
#' tick marks are hidden. Default \code{TRUE}.
#' @param show_y_axis
#' Logical scalar. When \code{FALSE}, y-axis text and
#' tick marks are hidden. Default \code{TRUE}.
#' @param col_label
#' Character scalar or \code{NULL}. When not
#' \code{NULL}, added as a bold column-header title
#' above the panel via \code{ggplot2::ggtitle()}.
#' Default \code{NULL}.
#' @param row_label
#' Character scalar or \code{NULL}. When not
#' \code{NULL}, added as a bold rotated y-axis title
#' for the panel row. Default \code{NULL}.
#' @return
#' A \code{ggplot} object representing one map panel.
#' @details
#' The function applies \code{ggview::canvas()} using the
#' supplied \code{graphical_options} and ends with
#' \code{ggplot2::coord_sf()} so that the
#' continent-specific bounding box takes precedence over
#' the automatic bounding box added by
#' \code{ggplot2::geom_sf()}.
#' @seealso
#' \code{\link{extract_anova_fractions}},
#' \code{\link{recalculate_anova_components}}
#' @export
build_map_panel <-
  function(
    sel_continent,
    sel_scale,
    sel_resolution,
    xlim_val,
    ylim_val,
    data_grid_with_results,
    data_coords_per_unit,
    sf_world,
    graphical_options,
    show_x_axis = TRUE,
    show_y_axis = TRUE,
    col_label = NULL,
    row_label = NULL
  ) {
    assertthat::assert_that(
      base::is.character(sel_continent),
      base::length(sel_continent) == 1L,
      msg = "'sel_continent' must be a character scalar."
    )

    assertthat::assert_that(
      base::is.character(sel_scale),
      base::length(sel_scale) == 1L,
      msg = "'sel_scale' must be a character scalar."
    )

    assertthat::assert_that(
      base::is.character(sel_resolution),
      base::length(sel_resolution) == 1L,
      msg = "'sel_resolution' must be a character scalar."
    )

    assertthat::assert_that(
      base::is.numeric(xlim_val),
      base::length(xlim_val) == 2L,
      msg = "'xlim_val' must be a numeric vector of length 2."
    )

    assertthat::assert_that(
      base::is.numeric(ylim_val),
      base::length(ylim_val) == 2L,
      msg = "'ylim_val' must be a numeric vector of length 2."
    )

    assertthat::assert_that(
      base::is.data.frame(data_grid_with_results),
      msg = "'data_grid_with_results' must be a data frame."
    )

    assertthat::assert_that(
      base::is.data.frame(data_coords_per_unit),
      msg = "'data_coords_per_unit' must be a data frame."
    )

    assertthat::assert_that(
      base::inherits(sf_world, "sf"),
      msg = "'sf_world' must be an sf object."
    )

    assertthat::assert_that(
      base::is.list(graphical_options),
      base::all(
        c("width", "height", "units", "dpi", "bg") %in%
          base::names(graphical_options)
      ),
      msg = "'graphical_options' must be a named list."
    )

    assertthat::assert_that(
      base::is.logical(show_x_axis),
      base::length(show_x_axis) == 1L,
      msg = "'show_x_axis' must be a logical scalar."
    )

    assertthat::assert_that(
      base::is.logical(show_y_axis),
      base::length(show_y_axis) == 1L,
      msg = "'show_y_axis' must be a logical scalar."
    )

    assertthat::assert_that(
      base::is.null(col_label) || (
        base::is.character(col_label) &&
          base::length(col_label) == 1L
      ),
      msg = "'col_label' must be NULL or a character scalar."
    )

    assertthat::assert_that(
      base::is.null(row_label) || (
        base::is.character(row_label) &&
          base::length(row_label) == 1L
      ),
      msg = "'row_label' must be NULL or a character scalar."
    )

    # Rectangle data for this continent x scale x resolution
    data_rects <-
      data_grid_with_results |>
      dplyr::filter(
        continent == sel_continent,
        scale == sel_scale,
        taxonomic_resolution == sel_resolution
      )

    # Combined cores for this continent x scale
    #   (resolution-independent)
    data_cores <-
      data_coords_per_unit |>
      dplyr::filter(
        continent == sel_continent,
        scale == sel_scale
      ) |>
      dplyr::pull(coords) |>
      purrr::list_rbind()

    flag_has_cores <-
      base::nrow(data_cores) > 0

    panel <-
      ggplot2::ggplot() +
      ggplot2::scale_fill_viridis_c(
        option = "viridis",
        name = "Associations (%)",
        limits = c(0, 100),
        na.value = "grey80",
        guide = ggplot2::guide_colorbar(
          barwidth = 3,
          barheight = 18
        )
      ) +
      ggplot2::labs(
        x = NULL,
        y = NULL
      ) +
      ggplot2::theme_classic() +
      ggplot2::theme(
        axis.text = ggplot2::element_text(size = 24),
        axis.ticks = ggplot2::element_line(
          linewidth = 0.3
        ),
        panel.border = ggplot2::element_rect(
          fill = NA,
          colour = "grey50",
          linewidth = 0.3
        ),
        legend.title = ggplot2::element_text(size = 28),
        legend.text = ggplot2::element_text(size = 24)
      ) +
      ggview::canvas(
        width = graphical_options[["width"]],
        height = graphical_options[["height"]],
        units = graphical_options[["units"]],
        dpi = graphical_options[["dpi"]],
        bg = graphical_options[["bg"]]
      ) +
      ggplot2::geom_sf(
        data = sf_world,
        fill = "grey70",
        colour = "white",
        linewidth = 0.2,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_rect(
        data = data_rects,
        mapping = ggplot2::aes(
          xmin = x_min,
          xmax = x_max,
          ymin = y_min,
          ymax = y_max,
          fill = assoc_pct
        ),
        alpha = 0.75,
        colour = "white",
        linewidth = 0.2
      )

    if (flag_has_cores) {
      panel <-
        panel +
        ggplot2::geom_point(
          data = data_cores,
          mapping = ggplot2::aes(
            x = coord_long,
            y = coord_lat
          ),
          size = 0.3,
          colour = "black",
          alpha = 0.5,
          inherit.aes = FALSE
        )
    }

    if (!show_x_axis) {
      panel <-
        panel +
        ggplot2::theme(
          axis.text.x = ggplot2::element_blank(),
          axis.ticks.x = ggplot2::element_blank()
        )
    }

    if (!show_y_axis) {
      panel <-
        panel +
        ggplot2::theme(
          axis.text.y = ggplot2::element_blank(),
          axis.ticks.y = ggplot2::element_blank()
        )
    }

    if (!base::is.null(col_label)) {
      panel <-
        panel +
        ggplot2::ggtitle(col_label) +
        ggplot2::theme(
          plot.title = ggplot2::element_text(
            hjust = 0.5,
            size = 28,
            face = "bold",
            margin = ggplot2::margin(b = 2)
          )
        )
    }

    if (!base::is.null(row_label)) {
      panel <-
        panel +
        ggplot2::labs(y = row_label) +
        ggplot2::theme(
          axis.title.y = ggplot2::element_text(
            angle = 90,
            size = 28,
            face = "bold",
            margin = ggplot2::margin(r = 4)
          )
        )
    }

    # coord_sf must be the final layer: geom_sf() adds its
    #   own coord_sf automatically, and ggplot2 applies the
    #   last added coord. Placing coord_sf here ensures the
    #   continent-specific xlim/ylim wins.
    return(
      panel +
        ggplot2::coord_sf(
          xlim = xlim_val,
          ylim = ylim_val,
          default_crs = sf::st_crs(4326),
          expand = FALSE
        )
    )
  }

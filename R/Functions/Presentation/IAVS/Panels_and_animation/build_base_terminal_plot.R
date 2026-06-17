#' @title Create an ORACLE terminal base plot
#' @description
#' Creates the reusable dark CRT terminal scaffold used by IAVS 2026
#' story and atmospheric figures.
#' @param title
#' Character scalar. Terminal heading shown at the top left.
#' @param prompt
#' Character scalar. Prompt or status text shown below the heading.
#' @param plot_dimensions
#' Named numeric vector with `x_min`, `x_max`, `y_min`, and `y_max`.
#' These values define the coordinate system for all subsequent layers.
#' @param boundary_buffer
#' Numeric scalar. Internal margin used for the terminal border and text.
#' @param width
#' Numeric scalar. Output canvas width passed to `ggview::canvas()`.
#' @param height
#' Numeric scalar. Output canvas height passed to `ggview::canvas()`.
#' @param units
#' Character scalar. Canvas units passed to `ggview::canvas()`.
#' @param dpi
#' Numeric scalar. Canvas resolution passed to `ggview::canvas()`.
#' @param palette
#' Optional named character vector of ORACLE colours. If `NULL`, colours
#' are read with `get_oracle_palette_values()`.
#' @param background_colour
#' Optional background colour. If `NULL`, `palette[["background"]]`
#' is used.
#' @param terminal_label
#' Character scalar. Footer label shown in amber at the lower left.
#' @param noise_points
#' Integer scalar. Number of faint CRT noise points to draw.
#' @param scanline_spacing
#' Numeric scalar. Vertical spacing between scanlines.
#' @return
#' A `ggplot` object with a configured terminal canvas.
#' @details
#' This function intentionally keeps scanline, CRT-noise, canvas, and
#' blank-theme helpers internal so presentation scripts can reuse one
#' stable public entry point.
#' @seealso add_panel, get_oracle_palette_values, create_oracle_theme
#' @export
build_base_terminal_plot <- function(
  title,
  prompt,
  plot_dimensions = c(
    x_min = 0,
    x_max = 100,
    y_min = 0,
    y_max = 100 * (9 / 16)
  ),
  boundary_buffer = 2,
  width = 1600,
  height = 900,
  units = "px",
  dpi = 300,
  palette = NULL,
  background_colour = NULL,
  terminal_label = ">ORACLE//",
  noise_points = 900L,
  scanline_spacing = 1.25
) {
  assertthat::assert_that(
    base::is.character(title),
    base::length(title) == 1L,
    msg = "'title' must be a character scalar."
  )
  assertthat::assert_that(
    base::is.character(prompt),
    base::length(prompt) == 1L,
    msg = "'prompt' must be a character scalar."
  )
  assertthat::assert_that(
    base::is.numeric(plot_dimensions),
    base::all(c("x_min", "x_max", "y_min", "y_max") %in%
      base::names(plot_dimensions)),
    msg = "'plot_dimensions' must name x_min, x_max, y_min, and y_max."
  )
  assertthat::assert_that(
    width > 0,
    height > 0,
    boundary_buffer >= 0,
    msg = "'width', 'height', and 'boundary_buffer' must be valid."
  )

  if (
    base::is.null(palette)
  ) {
    if (
      !base::exists("get_oracle_palette_values", mode = "function")
    ) {
      source(
        here::here(
          "R",
          "Functions",
          "Presentation",
          "IAVS",
          "Oracle_palettes",
          "get_oracle_palette_values.R"
        )
      )
    }

    palette <-
      get_oracle_palette_values()
  }

  if (
    base::is.null(background_colour)
  ) {
    background_colour <-
      palette[["background"]]
  }

  make_scanline_data <- function(
    spacing = scanline_spacing,
    alpha_limits = c(0, 0.06)
  ) {
    data_scanlines <-
      tibble::tibble(
        y = base::seq(
          from = plot_dimensions[["y_min"]],
          to = plot_dimensions[["y_max"]],
          by = spacing
        ),
        y_scaled = scales::rescale(y, to = c(0, 1)),
        alpha_raw = 0.01 + 0.5 * base::sin(y_scaled * base::pi)
      ) |>
      dplyr::mutate(
        alpha = scales::rescale(alpha_raw, to = alpha_limits)
      )

    return(data_scanlines)
  }

  make_noise_data <- function(
    n_points = noise_points,
    alpha_limits = c(0, 0.2)
  ) {
    base::set.seed(900723)

    x_mid <-
      (plot_dimensions[["x_max"]] + plot_dimensions[["x_min"]]) / 2
    y_mid <-
      (plot_dimensions[["y_max"]] + plot_dimensions[["y_min"]]) / 2
    x_half <-
      (plot_dimensions[["x_max"]] - plot_dimensions[["x_min"]]) / 2
    y_half <-
      (plot_dimensions[["y_max"]] - plot_dimensions[["y_min"]]) / 2

    data_noise <-
      tibble::tibble(
        x = stats::runif(
          n_points,
          min = plot_dimensions[["x_min"]] + boundary_buffer,
          max = plot_dimensions[["x_max"]] - boundary_buffer
        ),
        y = stats::runif(
          n_points,
          min = plot_dimensions[["y_min"]] + boundary_buffer,
          max = plot_dimensions[["y_max"]] - boundary_buffer
        ),
        alpha_raw = stats::runif(
          n_points,
          min = alpha_limits[1],
          max = alpha_limits[2]
        )
      ) |>
      dplyr::mutate(
        alpha = alpha_raw *
          (1 - (x - x_mid)^2 / x_half^2) *
          (1 - (y - y_mid)^2 / y_half^2),
        alpha = scales::rescale(alpha, to = alpha_limits)
      )

    return(data_noise)
  }

  add_terminal_canvas <- function() {
    list_canvas <-
      base::list(
        ggplot2::coord_cartesian(
          xlim = base::c(
            plot_dimensions[["x_min"]],
            plot_dimensions[["x_max"]]
          ),
          ylim = base::c(
            plot_dimensions[["y_min"]],
            plot_dimensions[["y_max"]]
          ),
          expand = FALSE,
          clip = "off"
        ),
        ggview::canvas(
          width = width,
          height = height,
          units = units,
          dpi = dpi,
          bg = background_colour
        )
      )

    return(list_canvas)
  }

  theme_terminal_blank <- function() {
    plot_theme <-
      ggplot2::theme_void(base_family = "mono") +
      ggplot2::theme(
        plot.background = ggplot2::element_rect(
          fill = background_colour,
          colour = NA
        ),
        panel.background = ggplot2::element_rect(
          fill = background_colour,
          colour = NA
        ),
        legend.position = "none",
        plot.margin = ggplot2::margin(8, 8, 8, 8)
      )

    return(plot_theme)
  }

  data_scanlines <-
    make_scanline_data()
  data_noise <-
    make_noise_data()

  plot <-
    ggplot2::ggplot() +
    theme_terminal_blank() +
    add_terminal_canvas() +
    ggplot2::geom_hline(
      yintercept = dplyr::pull(data_scanlines, y),
      colour = palette[["phosphor"]],
      linewidth = 0.05,
      alpha = dplyr::pull(data_scanlines, alpha)
    ) +
    ggplot2::geom_point(
      data = data_noise,
      mapping = ggplot2::aes(x = x, y = y),
      colour = palette[["phosphor"]],
      alpha = dplyr::pull(data_noise, alpha),
      size = 0.25
    ) +
    ggplot2::geom_rect(
      mapping = ggplot2::aes(
        xmin = plot_dimensions[["x_min"]] + boundary_buffer,
        xmax = plot_dimensions[["x_max"]] - boundary_buffer,
        ymin = plot_dimensions[["y_min"]] + boundary_buffer,
        ymax = plot_dimensions[["y_max"]] - boundary_buffer
      ),
      fill = NA,
      colour = palette[["border"]],
      linewidth = 0.28,
      alpha = 0.88
    ) +
    ggplot2::annotate(
      geom = "text",
      x = plot_dimensions[["x_min"]] + boundary_buffer,
      y = plot_dimensions[["y_max"]],
      label = title,
      hjust = 0,
      vjust = 0.3,
      colour = palette[["phosphor"]],
      family = "mono",
      fontface = "bold",
      size = 5.0
    ) +
    ggplot2::geom_segment(
      mapping = ggplot2::aes(
        x = plot_dimensions[["x_min"]] + boundary_buffer,
        xend = plot_dimensions[["x_max"]] - boundary_buffer,
        y = plot_dimensions[["y_max"]] - boundary_buffer / 2,
        yend = plot_dimensions[["y_max"]] - boundary_buffer / 2
      ),
      colour = palette[["border"]],
      linewidth = 0.22,
      alpha = 0.75
    ) +
    ggplot2::annotate(
      geom = "text",
      x = plot_dimensions[["x_min"]] + boundary_buffer * 1.5,
      y = plot_dimensions[["y_max"]] - boundary_buffer * 2,
      label = prompt,
      hjust = 0,
      colour = palette[["muted"]],
      family = "mono",
      size = 2.9
    ) +
    ggplot2::annotate(
      geom = "text",
      x = plot_dimensions[["x_min"]] + boundary_buffer * 1.5,
      y = plot_dimensions[["y_min"]] + boundary_buffer * 2,
      label = terminal_label,
      hjust = 0,
      colour = palette[["amber"]],
      family = "mono",
      size = 3.0
    )

  return(plot)
}

#' @title Add an ORACLE terminal panel
#' @description
#' Adds a framed translucent panel and optional label to an ORACLE terminal
#' plot.
#' @param xmin
#' Numeric scalar. Minimum x coordinate of the panel.
#' @param xmax
#' Numeric scalar. Maximum x coordinate of the panel.
#' @param ymin
#' Numeric scalar. Minimum y coordinate of the panel.
#' @param ymax
#' Numeric scalar. Maximum y coordinate of the panel.
#' @param label
#' Optional character scalar. Label shown inside the upper-left corner.
#' @param panel_fill
#' Optional fill colour. If `NULL`, `palette[["surface"]]` is used.
#' @param panel_border
#' Optional border colour. If `NULL`, `palette[["border"]]` is used.
#' @param label_colour
#' Optional label colour. If `NULL`, `palette[["muted"]]` is used.
#' @param label_size
#' Numeric scalar. Label text size.
#' @param text_buffer
#' Numeric scalar. Internal offset for label placement.
#' @param palette
#' Optional named character vector of ORACLE colours. If `NULL`, colours
#' are read with `oracle_palette_values()`.
#' @return
#' A list of `ggplot2` layers.
#' @details
#' The returned list is designed to be added to a `ggplot` object with `+`.
#' @seealso base_terminal_plot, oracle_palette_values
#' @export
add_panel <- function(
  xmin,
  xmax,
  ymin,
  ymax,
  label = NULL,
  panel_fill = NULL,
  panel_border = NULL,
  label_colour = NULL,
  label_size = 3.0,
  text_buffer = 1.2,
  palette = NULL
) {
  assertthat::assert_that(
    base::is.numeric(base::c(xmin, xmax, ymin, ymax)),
    xmin < xmax,
    ymin < ymax,
    msg = "Panel coordinates must be numeric and ordered."
  )

  if (
    base::is.null(palette)
  ) {
    if (
      !base::exists("oracle_palette_values", mode = "function")
    ) {
      source(
        here::here(
          "R",
          "Functions",
          "Presentation",
          "IAVS",
          "oracle_palette_values.R"
        )
      )
    }

    palette <-
      oracle_palette_values()
  }

  if (
    base::is.null(panel_fill)
  ) {
    panel_fill <-
      palette[["surface"]]
  }
  if (
    base::is.null(panel_border)
  ) {
    panel_border <-
      palette[["border"]]
  }
  if (
    base::is.null(label_colour)
  ) {
    label_colour <-
      palette[["muted"]]
  }

  list_layers <-
    base::list(
      ggplot2::geom_rect(
        mapping = ggplot2::aes(
          xmin = xmin,
          xmax = xmax,
          ymin = ymin,
          ymax = ymax
        ),
        fill = panel_fill,
        colour = panel_border,
        linewidth = 0.24,
        alpha = 0.55
      )
    )

  if (
    !base::is.null(label)
  ) {
    list_layers <-
      base::c(
        list_layers,
        base::list(
          ggplot2::annotate(
            geom = "text",
            x = xmin + text_buffer,
            y = ymax - text_buffer * 1.5,
            label = label,
            hjust = 0,
            colour = label_colour,
            family = "mono",
            size = label_size
          )
        )
      )
  }

  return(list_layers)
}
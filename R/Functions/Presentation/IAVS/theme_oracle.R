#' @title ORACLE ggplot2 theme
#' @description Applies the ORACLE colour palette and a minimal dark
#'   typographic layout to a ggplot2 plot.
#' @param base_size Numeric scalar. Base font size in points. Default `18`.
#' @param base_family Character scalar. Base font family. Defaults to
#'   `"mono"` when `NULL`.
#' @return A `ggplot2` theme object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'   ggplot2::geom_point() +
#'   theme_oracle()
#' }
theme_oracle <- function(base_size = 18, base_family = NULL) {
  assertthat::assert_that(
    base::is.numeric(base_size),
    base::length(base_size) == 1L,
    msg = "'base_size' must be a single numeric value."
  )
  if (
    !base::is.null(base_family)
  ) {
    assertthat::assert_that(
      base::is.character(base_family),
      base::length(base_family) == 1L,
      msg = "'base_family' must be NULL or a single character string."
    )
  }

  vec_palette <-
    oracle_palette_values()

  if (
    base::is.null(base_family)
  ) {
    base_family <- "mono"
  }

  return(
    ggplot2::theme_minimal(
      base_size = base_size,
      base_family = base_family
    ) +
      ggplot2::theme(
        text = ggplot2::element_text(colour = vec_palette[["text"]]),
        plot.background = ggplot2::element_rect(
          fill = vec_palette[["background"]],
          colour = NA
        ),
        panel.background = ggplot2::element_rect(
          fill = vec_palette[["surface"]],
          colour = NA
        ),
        panel.grid.major = ggplot2::element_line(
          colour = vec_palette[["border"]],
          linewidth = 0.25
        ),
        panel.grid.minor = ggplot2::element_blank(),
        axis.title = ggplot2::element_text(
          colour = vec_palette[["phosphor"]],
          face = "bold"
        ),
        axis.text = ggplot2::element_text(
          colour = vec_palette[["muted"]]
        ),
        axis.ticks = ggplot2::element_line(
          colour = vec_palette[["border"]]
        ),
        plot.title = ggplot2::element_text(
          colour = vec_palette[["phosphor"]],
          face = "bold",
          margin = ggplot2::margin(b = 8)
        ),
        plot.subtitle = ggplot2::element_text(
          colour = vec_palette[["cyan"]],
          margin = ggplot2::margin(b = 10)
        ),
        plot.caption = ggplot2::element_text(
          colour = vec_palette[["muted"]],
          size = ggplot2::rel(0.75)
        ),
        legend.background = ggplot2::element_rect(
          fill = vec_palette[["surface"]],
          colour = vec_palette[["border"]]
        ),
        legend.key = ggplot2::element_rect(
          fill = vec_palette[["surface"]],
          colour = NA
        ),
        legend.title = ggplot2::element_text(
          colour = vec_palette[["phosphor"]]
        ),
        legend.text = ggplot2::element_text(
          colour = vec_palette[["text"]]
        ),
        strip.background = ggplot2::element_rect(
          fill = vec_palette[["surface_alt"]],
          colour = vec_palette[["border"]]
        ),
        strip.text = ggplot2::element_text(
          colour = vec_palette[["phosphor"]],
          face = "bold"
        )
      )
  )
}

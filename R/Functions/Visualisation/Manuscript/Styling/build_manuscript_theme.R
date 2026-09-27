#' @title Build the Shared Manuscript Figure Theme
#' @description
#' Builds the journal-neutral theme used by main-analysis manuscript figures.
#' The theme uses a white background, conventional sans-serif typography, and
#' restrained grid lines suitable for print and screen review.
#' @param base_size Numeric scalar giving the base font size in points.
#' @param base_family Character scalar giving the font family.
#' @return A complete `ggplot2` theme object.
#' @export
build_manuscript_theme <- function(
    base_size = 9,
    base_family = "sans") {
  assertthat::assert_that(
    base::is.numeric(base_size),
    base::length(base_size) == 1L,
    base::is.finite(base_size),
    base_size > 0,
    msg = "`base_size` must be one positive finite number."
  )
  assertthat::assert_that(
    base::is.character(base_family),
    base::length(base_family) == 1L,
    !base::is.na(base_family),
    base::nzchar(base_family),
    msg = "`base_family` must be one non-empty string."
  )

  res_theme <-
    ggplot2::theme_minimal(
      base_size = base_size,
      base_family = base_family
    ) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(
        fill = "white",
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = "white",
        colour = NA
      ),
      panel.grid.major = ggplot2::element_line(
        colour = "grey88",
        linewidth = 0.25
      ),
      panel.grid.minor = ggplot2::element_blank(),
      axis.line = ggplot2::element_line(
        colour = "grey35",
        linewidth = 0.3
      ),
      axis.ticks = ggplot2::element_line(
        colour = "grey35",
        linewidth = 0.3
      ),
      axis.text = ggplot2::element_text(colour = "grey20"),
      axis.title = ggplot2::element_text(colour = "grey10"),
      strip.background = ggplot2::element_rect(
        fill = "grey95",
        colour = "grey75",
        linewidth = 0.25
      ),
      strip.text = ggplot2::element_text(
        colour = "grey10",
        face = "bold"
      ),
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_text(face = "bold"),
      legend.key = ggplot2::element_rect(
        fill = "white",
        colour = NA
      ),
      plot.title = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank(),
      plot.caption = ggplot2::element_text(
        colour = "grey35",
        hjust = 0
      ),
      plot.tag = ggplot2::element_text(face = "bold"),
      plot.tag.position = base::c(0, 1),
      plot.margin = ggplot2::margin(7, 8, 7, 8)
    )

  return(res_theme)
}

#' @title Build Node Box Geometry
#' @description
#' Creates one-row tibble geometry for labelled schematic boxes used in
#' IAVS figures.
#' @param id
#' Character scalar identifier.
#' @param label
#' Character scalar display label.
#' @param x
#' Numeric scalar. Box center x position.
#' @param y
#' Numeric scalar. Box center y position.
#' @param width
#' Numeric scalar. Box width.
#' @param height
#' Numeric scalar. Box height.
#' @param colour
#' Character scalar line colour.
#' @param fill
#' Character scalar fill colour.
#' @param text_colour
#' Character scalar text colour.
#' @param text_size
#' Numeric scalar text size.
#' @param fontface
#' Character scalar text face.
#' @return
#' One-row tibble with precomputed box extents and styling columns.
#' @export
node_box <- function(
    id,
    label,
    x,
    y,
    width,
    height,
    colour,
  fill = NA,
  text_colour = colour,
  text_size = 2.9,
    fontface = "bold") {
  assertthat::assert_that(
    base::is.character(id),
    base::length(id) == 1L,
    base::is.character(label),
    base::length(label) == 1L,
    msg = "'id' and 'label' must be character scalars."
  )

  assertthat::assert_that(
    base::is.numeric(base::c(x, y, width, height, text_size)),
    width > 0,
    height > 0,
    msg = paste(
      "'x', 'y', 'width', 'height', and 'text_size' must be numeric,",
      "with positive width and height."
    )
  )

  assertthat::assert_that(
    base::is.character(colour),
    base::length(colour) == 1L,
    (base::is.character(fill) && base::length(fill) == 1L) ||
      (base::is.logical(fill) && base::length(fill) == 1L),
    base::is.character(text_colour),
    base::length(text_colour) == 1L,
    base::is.character(fontface),
    base::length(fontface) == 1L,
    msg = paste(
      "'colour', 'fill', 'text_colour', and 'fontface' must be",
      "character scalars."
    )
  )

  res_box <-
    tibble::tibble(
      id = id,
      label = label,
      x = x,
      y = y,
      width = width,
      height = height,
      xmin = x - width / 2,
      xmax = x + width / 2,
      ymin = y - height / 2,
      ymax = y + height / 2,
      colour = colour,
      fill = fill,
      text_colour = text_colour,
      text_size = text_size,
      fontface = fontface
    )

  return(res_box)
}

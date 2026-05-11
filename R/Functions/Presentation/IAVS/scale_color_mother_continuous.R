#' @title Continuous color scale using MOTHER palette
#' @description US-spelling alias for `scale_colour_mother_continuous()`.
#' @inheritParams scale_colour_mother_continuous
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = disp)) +
#'   ggplot2::geom_point() +
#'   scale_color_mother_continuous()
#' }
scale_color_mother_continuous <- function(
    values = mother_continuous_palette(),
    ...) {
  return(scale_colour_mother_continuous(values = values, ...))
}

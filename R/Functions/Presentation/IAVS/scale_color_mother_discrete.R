#' @title Discrete color scale using MOTHER palette
#' @description US-spelling alias for `scale_colour_mother_discrete()`.
#' @inheritParams scale_colour_mother_discrete
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'   ggplot2::geom_point() +
#'   scale_color_mother_discrete()
#' }
scale_color_mother_discrete <- function(
    values = mother_discrete_palette(),
    ...) {
  return(scale_colour_mother_discrete(values = values, ...))
}

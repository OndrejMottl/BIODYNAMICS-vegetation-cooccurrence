#' @title Discrete color scale using ORACLE palette
#' @description US-spelling alias for `scale_colour_oracle_discrete()`.
#' @inheritParams scale_colour_oracle_discrete
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'   ggplot2::geom_point() +
#'   scale_color_oracle_discrete()
#' }
scale_color_oracle_discrete <- function(
    values = oracle_discrete_palette(),
    ...) {
  return(scale_colour_oracle_discrete(values = values, ...))
}

#' @title Discrete colour scale using the MOTHER palette
#' @description Maps discrete data values to MOTHER categorical colours
#'   using `ggplot2::scale_colour_manual()`.
#' @param values Named character vector of colours. Defaults to
#'   `mother_discrete_palette()`.
#' @param ... Additional arguments passed to
#'   `ggplot2::scale_colour_manual()`.
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
#'   ggplot2::geom_point() +
#'   scale_colour_mother_discrete()
#' }
scale_colour_mother_discrete <- function(
    values = mother_discrete_palette(),
    ...) {
  return(ggplot2::scale_colour_manual(values = base::unname(values), ...))
}

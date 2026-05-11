#' @title Continuous colour scale using the MOTHER palette
#' @description Maps continuous data to a MOTHER gradient using
#'   `ggplot2::scale_colour_gradientn()`.
#' @param values Named character vector of gradient stop colours. Defaults
#'   to `mother_continuous_palette()`.
#' @param ... Additional arguments passed to
#'   `ggplot2::scale_colour_gradientn()`.
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = disp)) +
#'   ggplot2::geom_point() +
#'   scale_colour_mother_continuous()
#' }
scale_colour_mother_continuous <- function(
    values = mother_continuous_palette(),
    ...) {
  return(
    ggplot2::scale_colour_gradientn(colours = base::unname(values), ...)
  )
}

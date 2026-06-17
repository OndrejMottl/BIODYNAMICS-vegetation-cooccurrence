#' @title Continuous colour scale using the ORACLE palette
#' @description Maps continuous data to an ORACLE gradient using
#'   `ggplot2::scale_colour_gradientn()`.
#' @param values Named character vector of gradient stop colours. Defaults
#'   to `get_oracle_continuous_palette()`.
#' @param ... Additional arguments passed to
#'   `ggplot2::scale_colour_gradientn()`.
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = disp)) +
#'   ggplot2::geom_point() +
#'   scale_colour_oracle_continuous()
#' }
scale_colour_oracle_continuous <- function(
    values = get_oracle_continuous_palette(),
    ...) {
  return(
    ggplot2::scale_colour_gradientn(colours = base::unname(values), ...)
  )
}

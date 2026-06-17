#' @title Continuous color scale using ORACLE palette
#' @description US-spelling alias for `scale_colour_oracle_continuous()`.
#' @inheritParams scale_colour_oracle_continuous
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = disp)) +
#'   ggplot2::geom_point() +
#'   scale_color_oracle_continuous()
#' }
scale_color_oracle_continuous <- function(
    values = oracle_continuous_palette(),
    ...) {
  return(scale_colour_oracle_continuous(values = values, ...))
}

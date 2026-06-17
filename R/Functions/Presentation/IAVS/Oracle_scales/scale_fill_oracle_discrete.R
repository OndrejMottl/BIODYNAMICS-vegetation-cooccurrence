#' @title Discrete fill scale using the ORACLE palette
#' @description Maps discrete data values to ORACLE categorical colours
#'   using `ggplot2::scale_fill_manual()`.
#' @param values Named character vector of colours. Defaults to
#'   `get_oracle_discrete_palette()`.
#' @param ... Additional arguments passed to
#'   `ggplot2::scale_fill_manual()`.
#' @return A `ggplot2` scale object.
#' @examples
#' \dontrun{
#' ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg,
#'   fill = factor(cyl))) +
#'   ggplot2::geom_col() +
#'   scale_fill_oracle_discrete()
#' }
scale_fill_oracle_discrete <- function(
    values = get_oracle_discrete_palette(),
    ...) {
  return(ggplot2::scale_fill_manual(values = base::unname(values), ...))
}

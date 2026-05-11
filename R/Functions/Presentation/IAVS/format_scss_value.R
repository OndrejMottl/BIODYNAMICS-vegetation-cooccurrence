#' @title Format a design token value as a SCSS string
#' @description Converts a scalar design token value to a character string
#'   suitable for SCSS output.
#' @param value A scalar R value from the design configuration.
#' @return Character scalar.
#' @keywords internal
#' @examples
#' \dontrun{
#' format_scss_value("#00ff00")
#' }
format_scss_value <- function(value) {
  if (
    base::length(value) != 1L || base::is.na(value)
  ) {
    return("")
  }

  return(base::as.character(value))
}

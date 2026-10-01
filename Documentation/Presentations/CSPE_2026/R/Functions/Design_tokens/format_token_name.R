#' @title Format a design token name
#' @description Converts underscore-separated config names to CSS
#'   hyphen-case token names.
#' @param name Character scalar or vector.
#' @return Character vector.
#' @keywords internal
#' @examples
#' \dontrun{
#' format_token_name("surface_alt")
#' }
format_token_name <- function(name) {
  return(stringr::str_replace_all(name, "_", "-"))
}

#' @title Flatten one design token node
#' @description Recursively flattens a nested design config node into a
#'   named list of scalar token values.
#' @param value A config node.
#' @param prefix Character scalar token prefix.
#' @return A flat named list.
#' @keywords internal
#' @examples
#' \dontrun{
#' flatten_token_node(list(a = "b"), "mother-test")
#' }
flatten_token_node <- function(value, prefix) {
  if (
    !base::exists("format_token_name", mode = "function")
  ) {
    base::source(
      here::here(
        "R",
        "Functions",
        "Presentation",
        "IAVS",
        "format_token_name.R"
      )
    )
  }

  if (
    base::is.list(value) && base::is.null(base::names(value))
  ) {
    return(
      purrr::set_names(
        value,
        stringr::str_c(prefix, "-", base::seq_along(value))
      )
    )
  }

  if (
    base::is.list(value)
  ) {
    list_pieces <-
      purrr::map(
        .x = base::names(value),
        .f = ~ flatten_token_node(
          value[[.x]],
          stringr::str_c(prefix, format_token_name(.x), sep = "-")
        )
      )

    return(base::unlist(list_pieces, recursive = FALSE))
  }

  return(purrr::set_names(base::list(value), prefix))
}

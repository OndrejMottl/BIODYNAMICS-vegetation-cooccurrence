#' @title Flatten design configuration into a token list
#' @description Recursively flattens all top-level design token sections
#'   except `metadata` into CSS/SCSS token key-value pairs.
#' @param design Named list as returned by `load_design_config()`.
#' @return A flat named list of scalar token values.
#' @keywords internal
#' @examples
#' \dontrun{
#' flatten_design_tokens(load_design_config())
#' }
flatten_design_tokens <- function(design) {
  assertthat::assert_that(
    base::is.list(design),
    msg = "'design' must be a list as returned by load_design_config()."
  )

  if (
    !base::exists("flatten_token_node", mode = "function")
  ) {
    base::source(
      here::here(
        "R",
        "Functions",
        "Presentation",
        "IAVS",
        "flatten_token_node.R"
      )
    )
  }
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

  list_config <-
    purrr::chuck(design, "config")

  vec_token_sections <-
    base::setdiff(
      base::names(list_config),
      "metadata"
    )

  list_tokens <-
    purrr::map(
      .x = vec_token_sections,
      .f = ~ flatten_token_node(
        list_config[[.x]],
        stringr::str_c("oracle", format_token_name(.x), sep = "-")
      )
    )

  return(base::unlist(list_tokens, recursive = FALSE))
}

#' @title Flatten design configuration into a token list
#' @description Recursively flattens the `palette`, `typography`,
#'   `effects`, and `spacing` sections into CSS/SCSS token key-value
#'   pairs.
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
    base::intersect(
      base::c("palette", "typography", "effects", "spacing"),
      base::names(list_config)
    )

  list_tokens <-
    purrr::map(
      .x = vec_token_sections,
      .f = ~ flatten_token_node(
        list_config[[.x]],
        stringr::str_c("mother", format_token_name(.x), sep = "-")
      )
    )

  return(base::unlist(list_tokens, recursive = FALSE))
}

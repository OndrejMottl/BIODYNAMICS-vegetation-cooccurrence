#' @title Get ORACLE palette colour values
#' @description Returns named colour values from the ORACLE design palette.
#' @param names Character vector of palette key names to retrieve, or
#'   `NULL` to return all values.
#' @return A named character vector of colour values.
#' @examples
#' \dontrun{
#' load_oracle_palette_values()
#' load_oracle_palette_values(base::c("phosphor", "cyan"))
#' }
load_oracle_palette_values <- function(names = NULL) {
  list_oracle_design <-
    load_design_config()

  vec_values <-
    purrr::chuck(list_oracle_design, "config") |>
    purrr::chuck("palette") |>
    base::unlist(use.names = TRUE)

  if (
    base::is.null(names)
  ) {
    return(vec_values)
  }

  assertthat::assert_that(
    base::is.character(names),
    msg = "'names' must be a character vector or NULL."
  )

  vec_missing_names <-
    base::setdiff(names, base::names(vec_values))

  if (
    base::length(vec_missing_names) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Unknown ORACLE palette value(s).",
        "i" = stringr::str_c(
          "Bad names: ",
          stringr::str_c(vec_missing_names, collapse = ", ")
        )
      )
    )
  }

  return(vec_values[names])
}

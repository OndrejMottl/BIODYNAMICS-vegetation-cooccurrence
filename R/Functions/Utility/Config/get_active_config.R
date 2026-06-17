#' @title Get Active Configuration Value
#' @description
#' Retrieves a specific configuration value from a YAML configuration file.
#' @param value
#' A character vector specifying the configuration key(s) to retrieve.
#' @param file
#' Path to the YAML configuration file (default: "config.yml").
#' @return
#' Value(s) associated with the specified key(s) in the configuration file.
#' @details
#' Validates input parameters, ensures the file is readable, and retrieves
#' configuration value(s) using `config::get`. Active configuration is set by
#' the `R_CONFIG_ACTIVE` environment variable.
#' @export
get_active_config <- function(
    value = NULL,
    file = here::here("config.yml")) {
  assertthat::assert_that(
    is.character(value) && length(value) > 0,
    msg = "value must be a character vector with at least one element"
  )

  assertthat::assert_that(
    assertthat::is.readable(file) && assertthat::has_extension(file, "yml"),
    msg = "file must be a readable YAML file"
  )

  config::get(
    value = value,
    config = Sys.getenv("R_CONFIG_ACTIVE"),
    use_parent = FALSE,
    file = file
  ) %>%
    return()
}

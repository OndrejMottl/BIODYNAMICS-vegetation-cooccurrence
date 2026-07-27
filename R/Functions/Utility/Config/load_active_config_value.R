#' @title Load Value from Active Configuration
#' @description
#' Loads one nested value from the active project configuration.
#' @param value
#' A character vector specifying the configuration key(s) to retrieve.
#' @param file
#' Path to the YAML configuration file (default: "config.yml").
#' @return
#' The value associated with the specified key path.
#' @details
#' The active configuration is set by `R_CONFIG_ACTIVE`. An unset or empty
#' value uses `default`. Explicit named access belongs in [load_config()] or
#' [load_config_value()].
#' @seealso [load_config()], [load_config_value()]
#' @export
load_active_config_value <- function(
    value,
    file = here::here("config.yml")) {
  assertthat::assert_that(
    base::is.character(value) &&
      base::length(value) > 0L &&
      base::all(!base::is.na(value)) &&
      base::all(base::nzchar(value)),
    msg = "`value` must contain non-empty configuration keys."
  )

  profile_id <-
    base::Sys.getenv(
      x = "R_CONFIG_ACTIVE",
      unset = "default"
    )

  if (
    !base::nzchar(profile_id)
  ) {
    profile_id <- "default"
  }

  configuration_value <-
    load_config_value(
      config_id = profile_id,
      value = value,
      file = file
    )

  return(configuration_value)
}

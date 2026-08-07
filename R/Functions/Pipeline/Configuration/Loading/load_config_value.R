#' @title Load Named Configuration Value
#' @description
#' Loads one nested value from a named project configuration.
#' @param config_id
#' Single non-empty configuration identifier declared in the YAML file.
#' @param value
#' Character vector specifying the nested configuration key path.
#' @param file
#' Path to the generated YAML configuration file.
#' @return
#' The value associated with the requested key path.
#' @details
#' Use [load_config()] when the complete named configuration is needed. This
#' function is the canonical project boundary around [config::get()] for values
#' from an explicitly named configuration.
#' @seealso [load_config()], [load_active_config_value()]
#' @export
load_config_value <- function(
    config_id,
    value,
    file = here::here("config.yml")) {
  assertthat::assert_that(
    base::is.character(config_id) &&
      base::length(config_id) == 1L &&
      !base::is.na(config_id) &&
      base::nzchar(config_id),
    msg = "`config_id` must be one non-empty string."
  )
  assertthat::assert_that(
    base::is.character(value) &&
      base::length(value) > 0L &&
      base::all(!base::is.na(value)) &&
      base::all(base::nzchar(value)),
    msg = "`value` must contain non-empty configuration keys."
  )
  assertthat::assert_that(
    base::is.character(file) &&
      base::length(file) == 1L &&
      !base::is.na(file) &&
      assertthat::is.readable(file) &&
      assertthat::has_extension(file, "yml"),
    msg = "`file` must be one readable YAML file."
  )

  configuration_value <-
    config::get(
      value = value,
      config = config_id,
      use_parent = FALSE,
      file = file
    )

  return(configuration_value)
}

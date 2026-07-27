#' @title Load Named Configuration
#' @description
#' Loads one complete resolved project configuration by its identifier.
#' @param config_id
#' Single non-empty configuration identifier declared in the YAML file.
#' @param file
#' Path to the generated YAML configuration file.
#' @return
#' The complete resolved named configuration.
#' @details
#' Use [load_config_value()] when only one nested configuration value is needed.
#' This function is the canonical project boundary around [config::get()] for
#' complete named configurations.
#' @seealso [load_config_value()], [load_active_config_value()]
#' @export
load_config <- function(
    config_id,
    file = here::here("config.yml")) {
  assertthat::assert_that(
    base::is.character(config_id) &&
      base::length(config_id) == 1L &&
      !base::is.na(config_id) &&
      base::nzchar(config_id),
    msg = "`config_id` must be one non-empty string."
  )
  assertthat::assert_that(
    base::is.character(file) &&
      base::length(file) == 1L &&
      !base::is.na(file) &&
      assertthat::is.readable(file) &&
      assertthat::has_extension(file, "yml"),
    msg = "`file` must be one readable YAML file."
  )

  list_config <-
    config::get(
      value = NULL,
      config = config_id,
      use_parent = FALSE,
      file = file
    )

  return(list_config)
}

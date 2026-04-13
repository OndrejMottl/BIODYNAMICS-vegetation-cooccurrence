#' @title Get Configuration Value with Fallback
#' @description
#' Retrieves a configuration value from the active configuration. If
#' the key is absent there, the function falls back to the same key in
#' a named fallback configuration.
#' @param config_section
#' A single character string naming the configuration section to read,
#' such as `"data_processing"`.
#' @param config_key
#' A single character string naming the configuration setting within
#' `config_section`.
#' @param fallback_config
#' A single character string naming the configuration to use when the
#' active configuration does not define `config_key`.
#' @param file
#' Path to the YAML configuration file. Defaults to
#' `here::here("config.yml")`.
#' @return
#' A scalar configuration value read from the active configuration or
#' from `fallback_config` when the active configuration does not define
#' `config_key`.
#' @details
#' The function is intended for pipelines that keep a shared set of
#' defaults in a dedicated configuration while still allowing
#' project-specific overrides in the active configuration. If
#' `R_CONFIG_ACTIVE` is unset, the helper reads from `"default"`.
#' Both the active config name and `fallback_config` must exist in the
#' YAML file.
#' @examples
#' get_config_value_with_fallback(
#'   config_section = "data_processing",
#'   config_key = "min_n_samples"
#' )
#' get_config_value_with_fallback(
#'   config_section = "data_processing",
#'   config_key = "ft_groups_min",
#'   fallback_config = "traits"
#' )
#' @seealso [get_active_config()]
#' @export
get_config_value_with_fallback <- function(
    config_section,
    config_key,
    fallback_config = "default",
    file = here::here("config.yml")) {
  assertthat::assert_that(
    base::is.character(config_section) &&
      base::length(config_section) == 1L &&
      !base::is.na(config_section) &&
      config_section != "",
    msg = "'config_section' must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(config_key) &&
      base::length(config_key) == 1L &&
      !base::is.na(config_key) &&
      config_key != "",
    msg = "'config_key' must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(fallback_config) &&
      base::length(fallback_config) == 1L &&
      !base::is.na(fallback_config) &&
      fallback_config != "",
    msg = "'fallback_config' must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(file) &&
      base::length(file) == 1L &&
      !base::is.na(file) &&
      file != "",
    msg = "'file' must be a single non-empty character path."
  )

  assertthat::assert_that(
    assertthat::is.readable(file) &&
      assertthat::has_extension(file, "yml"),
    msg = "'file' must be a readable YAML file."
  )

  list_config_file <-
    yaml::read_yaml(file)

  vec_config_names <-
    base::names(list_config_file)

  active_config_name <-
    base::Sys.getenv("R_CONFIG_ACTIVE")

  if (
    active_config_name == ""
  ) {
    active_config_name <-
      "default"
  }

  assertthat::assert_that(
    active_config_name %in% vec_config_names,
    msg = stringr::str_glue(
      "Active config '{active_config_name}' was not found in '{file}'."
    )
  )

  assertthat::assert_that(
    fallback_config %in% vec_config_names,
    msg = stringr::str_glue(
      "Fallback config '{fallback_config}' was not found in '{file}'."
    )
  )

  value_config <-
    purrr::pluck(
      list_config_file,
      active_config_name,
      config_section,
      config_key,
      .default = NULL
    )

  if (
    base::is.null(value_config)
  ) {
    value_config <-
      purrr::pluck(
        list_config_file,
        fallback_config,
        config_section,
        config_key,
        .default = NULL
      )
  }

  if (
    base::is.null(value_config)
  ) {
    cli::cli_abort(
      base::c(
        "Configuration key was not found.",
        "i" = stringr::str_glue(
          "Section '{config_section}' does not define '{config_key}' ",
          "in either the active config or '{fallback_config}'."
        )
      )
    )
  }

  res_value <-
    value_config

  return(res_value)
}
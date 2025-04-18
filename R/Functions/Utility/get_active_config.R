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

#' @title Validate the Active Configuration Profile Selection
#' @description
#' Checks that the active profile is explicitly authorized for a runner.
#' @param vec_allowed_roles
#' Non-empty character vector of profile roles authorized by the caller.
#' Production runners should retain the default `c("main", "smoke")`.
#' @param vec_allowed_statuses
#' Non-empty character vector of profile statuses authorized by the caller.
#' Production runners should retain the default `"active"`.
#' @param file
#' Path to the generated YAML configuration file.
#' @return
#' The validated `_profile` metadata, invisibly.
#' @details
#' Base and archived profiles are never executable. Main and smoke profiles
#' must also declare `selectable: true`. Dedicated reference or one-time
#' runners may explicitly authorize their role and status.
#' @export
validate_config_profile_selection <- function(
    vec_allowed_roles = base::c("main", "smoke"),
    vec_allowed_statuses = "active",
    file = here::here("config.yml")) {
  validate_allowed_values <- function(
      vec_values,
      argument_name,
      vec_supported_values) {
    flag_valid_values <-
      base::is.character(vec_values) &&
      base::length(vec_values) > 0L &&
      base::all(!base::is.na(vec_values)) &&
      base::all(base::nzchar(vec_values)) &&
      !base::any(base::duplicated(vec_values)) &&
      base::all(vec_values %in% vec_supported_values)

    assertthat::assert_that(
      flag_valid_values,
      msg = stringr::str_glue(
        "`{argument_name}` must contain unique values from: ",
        "{stringr::str_c(vec_supported_values, collapse = ', ')}."
      )
    )
  }

  vec_supported_roles <-
    base::c("base", "main", "smoke", "reference", "one_time")
  vec_supported_statuses <-
    base::c("active", "frozen", "archived")

  validate_allowed_values(
    vec_values = vec_allowed_roles,
    argument_name = "vec_allowed_roles",
    vec_supported_values = vec_supported_roles
  )
  validate_allowed_values(
    vec_values = vec_allowed_statuses,
    argument_name = "vec_allowed_statuses",
    vec_supported_values = vec_supported_statuses
  )

  sel_profile_id <-
    base::Sys.getenv(
      x = "R_CONFIG_ACTIVE",
      unset = "default"
    )

  if (
    !base::nzchar(sel_profile_id)
  ) {
    sel_profile_id <- "default"
  }

  list_profile_metadata <-
    load_config_value(
      config_id = sel_profile_id,
      value = "_profile",
      file = file
    )

  sel_profile_role <-
    list_profile_metadata[["role"]]
  sel_profile_status <-
    list_profile_metadata[["status"]]
  flag_profile_selectable <-
    list_profile_metadata[["selectable"]]

  flag_valid_metadata <-
    base::is.character(sel_profile_role) &&
    base::length(sel_profile_role) == 1L &&
    !base::is.na(sel_profile_role) &&
    sel_profile_role %in% vec_supported_roles &&
    base::is.character(sel_profile_status) &&
    base::length(sel_profile_status) == 1L &&
    !base::is.na(sel_profile_status) &&
    sel_profile_status %in% vec_supported_statuses &&
    base::is.logical(flag_profile_selectable) &&
    base::length(flag_profile_selectable) == 1L &&
    !base::is.na(flag_profile_selectable)

  assertthat::assert_that(
    flag_valid_metadata,
    msg = stringr::str_glue(
      "Configuration profile '{sel_profile_id}' has invalid metadata. ",
      "Regenerate config.yml from Configuration/."
    )
  )

  if (
    sel_profile_role == "base"
  ) {
    cli::cli_abort(
      base::c(
        "Configuration profile {.val {sel_profile_id}} is a base profile.",
        "i" = "Select an executable main or smoke profile."
      )
    )
  }

  if (
    sel_profile_status == "archived"
  ) {
    cli::cli_abort(
      base::c(
        "Configuration profile {.val {sel_profile_id}} is archived.",
        "i" = "Archived profiles cannot be executed."
      )
    )
  }

  if (
    !sel_profile_role %in% vec_allowed_roles ||
      !sel_profile_status %in% vec_allowed_statuses
  ) {
    cli::cli_abort(
      base::c(
        "Configuration profile {.val {sel_profile_id}} is not authorized.",
        "x" = stringr::str_glue(
          "Selected role/status: ",
          "{sel_profile_role}/{sel_profile_status}."
        ),
        "i" = paste(
          "This runner allows roles",
          stringr::str_c(vec_allowed_roles, collapse = ", "),
          "and statuses",
          stringr::str_c(vec_allowed_statuses, collapse = ", "),
          "only."
        )
      )
    )
  }

  if (
    sel_profile_role %in% base::c("main", "smoke") &&
      !flag_profile_selectable
  ) {
    cli::cli_abort(
      base::c(
        "Configuration profile {.val {sel_profile_id}} is not selectable.",
        "i" = "Main and smoke profiles must declare `selectable: true`."
      )
    )
  }

  return(base::invisible(list_profile_metadata))
}

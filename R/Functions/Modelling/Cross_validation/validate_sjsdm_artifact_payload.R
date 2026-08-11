#' @title Validate an sjSDM Artifact Payload
#' @description
#' Validates the exact registered payload names, container types, and
#' duplicate rows for one v2 artifact type.
#' @param artifact_type Registered artifact type.
#' @param payload Named payload list.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_artifact_payload <- function(
    artifact_type = NULL,
    payload = NULL) {
  list_registry <-
    build_sjsdm_artifact_registry()

  assertthat::assert_that(
    base::is.character(artifact_type),
    base::length(artifact_type) == 1L,
    artifact_type %in% base::names(list_registry),
    base::is.list(payload),
    base::identical(
      base::names(payload),
      list_registry[[artifact_type]]
    ),
    msg = "The artifact payload does not match its registered contract."
  )

  vec_table_names <-
    base::names(payload)[stringr::str_starts(
      base::names(payload),
      "data_"
    )]

  if (
    !purrr::every(payload[vec_table_names], base::is.data.frame)
  ) {
    cli::cli_abort("Every data payload field must be a data frame.")
  }

  vec_list_names <-
    base::names(payload)[stringr::str_starts(
      base::names(payload),
      "list_"
    )]

  if (
    !purrr::every(payload[vec_list_names], base::is.list)
  ) {
    cli::cli_abort("Every list payload field must be a list.")
  }

  flag_has_duplicate_rows <-
    purrr::some(
      payload[vec_table_names],
      ~ base::nrow(.x) > 0L && base::any(base::duplicated(.x))
    )

  if (
    flag_has_duplicate_rows
  ) {
    cli::cli_abort("Artifact table payloads must not contain duplicate rows.")
  }

  return(base::invisible(TRUE))
}

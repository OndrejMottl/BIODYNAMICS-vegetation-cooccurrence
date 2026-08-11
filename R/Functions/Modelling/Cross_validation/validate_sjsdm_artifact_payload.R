#' @title Validate an sjSDM Artifact Payload
#' @description
#' Validates the exact registered payload names, container types, and
#' duplicate rows for one v2 artifact type.
#' @param artifact_type Registered artifact type.
#' @param payload Named payload list.
#' @param list_table_contracts
#' Optional named list of exact table contracts. Each contract may define
#' `columns`, `types`, `keys`, `statuses`, and `n_rows`.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_artifact_payload <- function(
    artifact_type = NULL,
    payload = NULL,
    list_table_contracts = base::list()) {
  list_registry <-
    build_sjsdm_artifact_registry()

  assertthat::assert_that(
    base::is.character(artifact_type),
    base::length(artifact_type) == 1L,
    artifact_type %in% base::names(list_registry),
    base::is.list(payload),
    base::is.list(list_table_contracts),
    !base::any(base::duplicated(base::names(list_table_contracts))),
    base::all(
      base::names(list_table_contracts) %in% base::names(payload)
    ),
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

  flag_valid_table_names <-
    purrr::every(
      payload[vec_table_names],
      ~ {
        vec_names <-
          base::colnames(.x)

        base::is.character(vec_names) &&
          !base::any(base::is.na(vec_names)) &&
          base::all(base::nzchar(vec_names)) &&
          !base::any(base::duplicated(vec_names))
      }
    )

  if (
    !flag_valid_table_names
  ) {
    cli::cli_abort(
      "Artifact tables must have unique, non-empty column names."
    )
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

  for (table_name in base::names(list_table_contracts)) {
    data_value <-
      payload[[table_name]]

    list_contract <-
      list_table_contracts[[table_name]]

    assertthat::assert_that(
      base::is.list(list_contract),
      msg = "Every table contract must be a named list."
    )

    vec_columns <-
      list_contract[["columns"]]

    n_rows <-
      list_contract[["n_rows"]]

    if (
      !base::is.null(n_rows) && base::nrow(data_value) != n_rows
    ) {
      cli::cli_abort(
        "Artifact table {.val {table_name}} has an invalid row count."
      )
    }

    if (
      !base::is.null(vec_columns) &&
        !base::identical(base::colnames(data_value), vec_columns)
    ) {
      cli::cli_abort(
        "Artifact table {.val {table_name}} has an invalid column schema."
      )
    }

    vec_types <-
      list_contract[["types"]]

    if (
      !base::is.null(vec_types)
    ) {
      vec_observed_types <-
        base::vapply(data_value, base::typeof, base::character(1L))

      if (
        !base::identical(vec_observed_types, vec_types)
      ) {
        cli::cli_abort(
          "Artifact table {.val {table_name}} has invalid column types."
        )
      }
    }

    vec_keys <-
      list_contract[["keys"]]

    if (
      !base::is.null(vec_keys)
    ) {
      if (
        !base::all(vec_keys %in% base::colnames(data_value))
      ) {
        cli::cli_abort(
          "Artifact table {.val {table_name}} is missing key columns."
        )
      }

      if (
        base::nrow(data_value) > 0L &&
          base::any(base::duplicated(data_value[vec_keys]))
      ) {
        cli::cli_abort(
          "Artifact table {.val {table_name}} has duplicate keys."
        )
      }
    }

    list_statuses <-
      list_contract[["statuses"]]

    if (
      !base::is.null(list_statuses)
    ) {
      for (status_name in base::names(list_statuses)) {
        vec_status <-
          data_value[[status_name]]

        vec_allowed <-
          list_statuses[[status_name]]

        flag_valid_status <-
          base::is.character(vec_status) &&
          base::all(base::is.na(vec_status) | vec_status %in% vec_allowed)

        if (
          !flag_valid_status
        ) {
          cli::cli_abort(
            "Artifact table {.val {table_name}} has an invalid status."
          )
        }
      }
    }
  }

  return(base::invisible(TRUE))
}

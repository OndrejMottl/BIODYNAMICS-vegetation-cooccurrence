#' @title Validate an sjSDM Artifact Table
#' @description
#' Applies an exact column, type, key, row-count, and status contract to one
#' table nested anywhere inside a v2 cross-validation artifact.
#' @param data_value Artifact table.
#' @param table_name Human-readable payload field name.
#' @param columns Exact ordered column names.
#' @param types Exact named base types returned by [base::typeof()].
#' @param keys Optional unique key columns.
#' @param statuses Optional named list of allowed character values.
#' @param n_rows Optional exact row count.
#' @return Invisible `TRUE`; invalid tables abort.
#' @export
validate_sjsdm_artifact_table <- function(
    data_value = NULL,
    table_name = NULL,
    columns = NULL,
    types = NULL,
    keys = NULL,
    statuses = base::list(),
    n_rows = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_value),
    base::is.character(table_name),
    base::length(table_name) == 1L,
    !base::is.na(table_name),
    base::nzchar(table_name),
    base::is.character(columns),
    base::is.character(types),
    base::is.list(statuses),
    msg = "The artifact table contract is malformed."
  )

  if (
    !base::identical(base::colnames(data_value), columns)
  ) {
    cli::cli_abort(
      "Artifact table {.val {table_name}} has an invalid column schema."
    )
  }

  vec_observed_types <-
    base::vapply(data_value, base::typeof, base::character(1L))

  if (
    !base::identical(vec_observed_types, types)
  ) {
    cli::cli_abort(
      "Artifact table {.val {table_name}} has invalid column types."
    )
  }

  if (
    !base::is.null(n_rows) && base::nrow(data_value) != n_rows
  ) {
    cli::cli_abort(
      "Artifact table {.val {table_name}} has an invalid row count."
    )
  }

  if (
    base::nrow(data_value) > 0L &&
      base::any(base::duplicated(data_value))
  ) {
    cli::cli_abort(
      "Artifact table {.val {table_name}} has duplicate rows."
    )
  }

  if (
    !base::is.null(keys)
  ) {
    if (
      !base::all(keys %in% columns)
    ) {
      cli::cli_abort(
        "Artifact table {.val {table_name}} is missing key columns."
      )
    }

    if (
      base::nrow(data_value) > 0L &&
        base::any(base::duplicated(data_value[keys]))
    ) {
      cli::cli_abort(
        "Artifact table {.val {table_name}} has duplicate keys."
      )
    }
  }

  for (status_name in base::names(statuses)) {
    vec_status <-
      data_value[[status_name]]

    vec_allowed <-
      statuses[[status_name]]

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

  return(base::invisible(TRUE))
}

#' @title Validate Provenance Columns of a Published Model Table
#' @description
#' Aborts when a published model table lacks a provenance column, or when a
#' checked row has a missing provenance value.
#' @param data_table
#' Published model table.
#' @param vec_required_columns
#' Provenance columns every checked row must carry.
#' @param availability_column
#' Optional column name. When supplied, only rows whose value is `available`
#' are checked, so rows describing missing or infeasible models may leave
#' provenance empty.
#' @param table_label
#' Label used in error messages, usually the table file name.
#' @return
#' Invisibly, `data_table` when every checked row has complete provenance.
#' @examples
#' validate_model_table_provenance(
#'   data_table = tibble::tibble(
#'     regularization_source = "unit_cv",
#'     candidate_id = "candidate_001",
#'     cv_strategy = "grouped_kfold",
#'     final_model_built_at = "2026-11-16 10:00:00",
#'     variance_partition_built_at = "2026-11-16 11:00:00"
#'   )
#' )
#' @export
validate_model_table_provenance <- function(
    data_table,
    vec_required_columns = base::c(
      "regularization_source",
      "candidate_id",
      "cv_strategy",
      "final_model_built_at",
      "variance_partition_built_at"
    ),
    availability_column = NULL,
    table_label = "model table") {
  assertthat::assert_that(
    base::is.data.frame(data_table),
    msg = "`data_table` must be a data frame."
  )
  assertthat::assert_that(
    base::is.character(vec_required_columns),
    base::length(vec_required_columns) > 0L,
    msg = "`vec_required_columns` must be a non-empty character vector."
  )
  assertthat::assert_that(
    base::is.null(availability_column) ||
      (
        assertthat::is.string(availability_column) &&
          availability_column %in% base::names(data_table)
      ),
    msg = "`availability_column` must be NULL or a column of `data_table`."
  )
  assertthat::assert_that(
    assertthat::is.string(table_label),
    msg = "`table_label` must be one string."
  )

  vec_missing_columns <-
    base::setdiff(vec_required_columns, base::names(data_table))

  if (
    base::length(vec_missing_columns) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "{table_label} lacks provenance columns.",
        "x" = "{vec_missing_columns}"
      ),
      class = "model_table_provenance_missing_columns"
    )
  }

  data_checked <-
    if (
      base::is.null(availability_column)
    ) {
      data_table
    } else {
      data_table |>
        dplyr::filter(.data[[availability_column]] == "available")
    }

  vec_incomplete_columns <-
    vec_required_columns |>
    purrr::keep(
      .p = ~ {
        vec_values <- data_checked[[.x]]
        base::any(
          base::is.na(vec_values) |
            !base::nzchar(base::as.character(vec_values))
        )
      }
    )

  if (
    base::length(vec_incomplete_columns) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "{table_label} has rows without provenance.",
        "x" = "{vec_incomplete_columns}"
      ),
      class = "model_table_provenance_missing_values"
    )
  }

  return(base::invisible(data_table))
}

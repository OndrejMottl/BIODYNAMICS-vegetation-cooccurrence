#' @title Extract a Model Tuning Integer
#' @description
#' Extracts one integer value from a one-row model tuning table.
#' @param data_tuning_row
#' One-row data frame containing model tuning values.
#' @param column_name
#' Single character string naming the value to extract.
#' @param scale_id
#' Single character string used in validation messages.
#' @param required
#' Logical indicating whether a missing value should raise an error.
#' @return
#' A single integer, or `NULL` for an optional missing value.
#' @export
extract_model_tuning_integer <- function(
    data_tuning_row,
    column_name,
    scale_id,
    required = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_tuning_row) &&
      base::nrow(data_tuning_row) == 1L,
    msg = "`data_tuning_row` must contain exactly one row."
  )

  assertthat::assert_that(
    base::is.character(column_name) &&
      base::length(column_name) == 1L &&
      column_name %in% base::colnames(data_tuning_row),
    msg = "`column_name` must identify one tuning column."
  )

  assertthat::assert_that(
    assertthat::is.flag(required),
    msg = "`required` must be `TRUE` or `FALSE`."
  )

  value <-
    dplyr::pull(data_tuning_row, column_name)

  if (
    base::is.na(value)
  ) {
    if (
      base::isTRUE(required)
    ) {
      cli::cli_abort(
        "`{column_name}` must not be missing for scale_id '{scale_id}'."
      )
    }

    return(NULL)
  }

  return(base::as.integer(value))
}

#' @title Coerce Null to Missing Integer
#' @description
#' Converts a scalar value to integer while representing `NULL` as
#' `NA_integer_`. This is useful for optional model tuning values that
#' are stored as missing values in CSV files but returned as `NULL` by
#' tuning helpers.
#' @param value
#' `NULL` or a scalar value coercible to integer.
#' @return
#' A single integer value, or `NA_integer_` when `value` is `NULL`.
#' @examples
#' coerce_null_to_na_integer(NULL)
#' coerce_null_to_na_integer(10)
#' @export
coerce_null_to_na_integer <- function(value) {
  if (
    base::is.null(value)
  ) {
    return(NA_integer_)
  }

  assertthat::assert_that(
    base::length(value) == 1L,
    msg = "`value` must be NULL or a scalar value."
  )

  res <-
    base::as.integer(value)

  return(res)
}

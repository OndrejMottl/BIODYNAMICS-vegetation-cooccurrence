#' @title Assert Prediction Probabilities
#' @description
#' Validates that a prediction matrix or data frame contains finite
#' probability-scale values bounded by zero and one.
#' @param data_predictions
#' Numeric matrix or data frame of predicted probabilities.
#' @param tolerance
#' Numeric scalar tolerance for small floating-point excursions beyond
#' zero and one.
#' @return
#' The input `data_predictions`, unchanged.
#' @examples
#' assert_prediction_probabilities(
#'   data_predictions = matrix(c(0.1, 0.9), nrow = 1)
#' )
#' @export
assert_prediction_probabilities <- function(
    data_predictions,
    tolerance = 1e-8) {
  assertthat::assert_that(
    base::is.matrix(data_predictions) ||
      base::is.data.frame(data_predictions),
    msg = "`data_predictions` must be a matrix or data frame."
  )

  assertthat::assert_that(
    base::is.numeric(tolerance) &&
      base::length(tolerance) == 1L &&
      base::is.finite(tolerance) &&
      tolerance >= 0,
    msg = "`tolerance` must be a single non-negative finite number."
  )

  mat_predictions <-
    base::as.matrix(data_predictions)

  assertthat::assert_that(
    base::is.numeric(mat_predictions),
    msg = "`data_predictions` must contain only numeric values."
  )

  assertthat::assert_that(
    base::nrow(mat_predictions) > 0L &&
      base::ncol(mat_predictions) > 0L,
    msg = "`data_predictions` must have at least one row and column."
  )

  if (
    base::any(!base::is.finite(mat_predictions))
  ) {
    cli::cli_abort(
      "Prediction probabilities must contain only finite values."
    )
  }

  if (
    base::any(mat_predictions < -tolerance) ||
      base::any(mat_predictions > 1 + tolerance)
  ) {
    cli::cli_abort(
      "Predicted probabilities must be bounded between 0 and 1."
    )
  }

  return(data_predictions)
}

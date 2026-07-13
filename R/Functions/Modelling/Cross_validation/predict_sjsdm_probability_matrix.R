#' @title Predict sjSDM Probability Matrix
#' @description
#' Predicts held-out probabilities from a fitted sjSDM object using fold-local
#' test inputs.
#' @param object
#' Fitted sjSDM-like model object.
#' @param data_test_input
#' Fold-local test input containing `data_abiotic_to_fit` and optionally
#' `data_spatial_to_fit`.
#' @param predict_function
#' Injectable prediction function. Defaults to [stats::predict()].
#' @return
#' Numeric matrix of probabilities aligned to the test input rows.
#' @export
predict_sjsdm_probability_matrix <- function(
    object = NULL,
    data_test_input = NULL,
    predict_function = stats::predict) {
  assertthat::assert_that(
    base::is.list(data_test_input),
    "data_abiotic_to_fit" %in% base::names(data_test_input),
    base::is.data.frame(data_test_input[["data_abiotic_to_fit"]]),
    base::is.function(predict_function),
    msg = "data_test_input must contain abiotic data and a predictor."
  )

  data_spatial <-
    if (
      "data_spatial_to_fit" %in% base::names(data_test_input)
    ) {
      data_test_input[["data_spatial_to_fit"]]
    } else {
      NULL
    }

  res_raw <-
    predict_function(
      object = object,
      newdata = data_test_input[["data_abiotic_to_fit"]],
      SP = data_spatial,
      type = "link"
    )

  res <-
    base::as.matrix(res_raw)

  if (
    !base::is.numeric(res) ||
      !base::all(base::is.finite(res)) ||
      !base::all(res >= 0) ||
      !base::all(res <= 1)
  ) {
    cli::cli_abort("Predicted probabilities must be finite values in [0, 1].")
  }

  return(res)
}

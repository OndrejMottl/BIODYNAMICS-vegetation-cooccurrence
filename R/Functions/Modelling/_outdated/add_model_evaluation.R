#' @title Add Model Evaluation
#' @description
#' Evaluates a fitted Hmsc model using predicted data and returns a list
#' containing the model and its evaluation.
#' @param mod_fitted A fitted Hmsc model object. Must be of class 'Hmsc'.
#' @param data_pred An array of predicted values. Must be of class 'array'.
#' @return
#' A list with two elements: the fitted model ('mod') and the evaluation
#' results ('eval').
#' @seealso Hmsc::evaluateModelFit
#' @export
add_model_evaluation <- function(mod_fitted = NULL,
                                 data_pred = NULL) {
  assertthat::assert_that(
    class(mod_fitted) == "Hmsc",
    msg = "mod_fitted must be of class Hmsc"
  )

  assertthat::assert_that(
    class(data_pred) == "array",
    msg = "data_pred must be an array"
  )

  list_eval <-
    Hmsc::evaluateModelFit(
      hM = mod_fitted,
      predY = data_pred
    )

  res <-
    list(
      mod = mod_fitted,
      eval = list_eval
    )

  return(res)
}

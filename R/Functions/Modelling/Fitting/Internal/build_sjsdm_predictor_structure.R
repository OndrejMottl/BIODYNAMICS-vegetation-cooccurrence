#' @title Build an sjSDM Predictor Structure
#' @description
#' Internal helper that builds linear, DNN, or absent predictor structures.
#' @param data_predictors Predictor data frame or `NULL` for no structure.
#' @param predictor_formula Formula passed to the sjSDM structure constructor.
#' @param predictor_method One of `"linear"`, `"DNN"`, or `"none"`.
#' @param lambda,alpha Regularisation settings for linear structures.
#' @return An sjSDM predictor structure or `NULL`.
#' @keywords internal
#' @keywords internal
.build_sjsdm_predictor_structure <- function(
    data_predictors = NULL,
    predictor_formula = NULL,
    predictor_method = c("linear", "DNN", "none"),
    lambda = 0,
    alpha = 0.5) {
  predictor_method <- base::match.arg(predictor_method)

  if (
    predictor_method == "none"
  ) {
    return(NULL)
  }

  # sjSDM constructors use match.call() and re-evaluate formula symbols.
  # do.call() passes the formula as an already evaluated object.
  if (
    predictor_method == "linear"
  ) {
    return(
      base::do.call(
        sjSDM::linear,
        base::list(
          data = data_predictors,
          formula = predictor_formula,
          lambda = lambda,
          alpha = alpha
        )
      )
    )
  }

  return(
    base::do.call(
      sjSDM::DNN,
      base::list(
        data = data_predictors,
        formula = predictor_formula
      )
    )
  )
}

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

#' @title Fit a Binary Calibration Model
#' @description
#' Fits one binomial calibration model while recording suppressed warnings.
#' @param formula_calibration
#' Formula used for the calibration model.
#' @param data_calibration
#' Data frame containing observed responses and predicted logits.
#' @return
#' A list containing the fitted model and a warning flag.
#' @keywords internal
.fit_binary_calibration_model <- function(
    formula_calibration,
    data_calibration) {
  flag_fit_warning <- FALSE

  mod_calibration <-
    base::withCallingHandlers(
      base::tryCatch(
        stats::glm(
          formula = formula_calibration,
          data = data_calibration,
          family = stats::binomial()
        ),
        error = function(condition) NULL
      ),
      warning = function(condition) {
        flag_fit_warning <<- TRUE
        base::invokeRestart("muffleWarning")
      }
    )

  res <-
    base::list(
      model = mod_calibration,
      flag_warning = flag_fit_warning
    )

  return(res)
}

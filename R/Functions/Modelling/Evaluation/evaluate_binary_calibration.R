#' @title Evaluate Binary Calibration
#' @description
#' Estimates calibration-in-the-large and calibration slope on the logit scale
#' while preserving explicit statuses for non-estimable cases.
#' @param observed
#' Numeric binary observation vector.
#' @param predicted_probability
#' Numeric predicted-probability vector aligned with `observed`.
#' @param epsilon
#' Single numeric clipping tolerance strictly between zero and `0.5`.
#' Defaults to `1e-6`.
#' @return
#' One-row tibble containing the calibration intercept, calibration slope,
#' separate estimation statuses, observation counts, prevalence, and clipping
#' tolerance. The intercept is estimated with predicted logits as an offset;
#' the slope is estimated jointly with a free intercept.
#' @details
#' Both coefficients are undefined for one-class observations. The slope is
#' additionally undefined for constant predictions or complete separation.
#' @examples
#' evaluate_binary_calibration(
#'   observed = c(0, 1, 0, 1),
#'   predicted_probability = c(0.2, 0.4, 0.6, 0.8)
#' )
#' @export
evaluate_binary_calibration <- function(
    observed = NULL,
    predicted_probability = NULL,
    epsilon = 1e-6) {
  flag_valid_epsilon <-
    base::is.numeric(epsilon) &&
    base::length(epsilon) == 1L &&
    base::is.finite(epsilon) &&
    epsilon > 0 &&
    epsilon < 0.5

  assertthat::assert_that(
    flag_valid_epsilon,
    msg = "`epsilon` must be a single finite number between 0 and 0.5."
  )

  list_input <-
    prepare_binary_prediction_metric_input(
      observed = observed,
      predicted_probability = predicted_probability
    )

  vec_observed <-
    list_input |>
    purrr::chuck("observed")

  vec_predicted_probability <-
    list_input |>
    purrr::chuck("predicted_probability")

  class_status <-
    list_input |>
    purrr::chuck("class_status")

  calibration_intercept <- NA_real_
  calibration_slope <- NA_real_
  intercept_status <- class_status
  slope_status <- class_status

  fit_calibration_model <- function(
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

    res_fit <-
      base::list(
        model = mod_calibration,
        flag_warning = flag_fit_warning
      )

    return(res_fit)
  }

  if (
    class_status == "ok"
  ) {
    vec_predicted_clipped <-
      base::pmin(
        base::pmax(vec_predicted_probability, epsilon),
        1 - epsilon
      )

    vec_predicted_logit <-
      stats::qlogis(vec_predicted_clipped)

    data_calibration <-
      tibble::tibble(
        observed = vec_observed,
        predicted_logit = vec_predicted_logit
      )

    list_intercept_fit <-
      fit_calibration_model(
        formula_calibration =
          observed ~ 1 + offset(predicted_logit),
        data_calibration = data_calibration
      )

    mod_intercept <-
      list_intercept_fit |>
      purrr::chuck("model")

    flag_intercept_warning <-
      list_intercept_fit |>
      purrr::chuck("flag_warning")

    flag_intercept_ok <-
      !base::is.null(mod_intercept) &&
      !flag_intercept_warning &&
      base::isTRUE(mod_intercept[["converged"]]) &&
      base::is.finite(stats::coef(mod_intercept)[[1L]])

    if (
      flag_intercept_ok
    ) {
      calibration_intercept <-
        base::unname(stats::coef(mod_intercept)[[1L]])
      intercept_status <- "ok"
    } else if (
      flag_intercept_warning
    ) {
      intercept_status <- "undefined_fit_warning"
    } else {
      intercept_status <- "undefined_fit_failure"
    }

    flag_constant_predictions <-
      dplyr::n_distinct(vec_predicted_logit) == 1L

    vec_presence_logit <-
      vec_predicted_logit[vec_observed == 1L]

    vec_absence_logit <-
      vec_predicted_logit[vec_observed == 0L]

    flag_separation <-
      base::max(vec_absence_logit) <= base::min(vec_presence_logit) ||
      base::max(vec_presence_logit) <= base::min(vec_absence_logit)

    if (
      flag_constant_predictions
    ) {
      slope_status <- "undefined_constant_predictions"
    } else if (
      flag_separation
    ) {
      slope_status <- "undefined_separation"
    } else {
      list_slope_fit <-
        fit_calibration_model(
          formula_calibration = observed ~ predicted_logit,
          data_calibration = data_calibration
        )

      mod_slope <-
        list_slope_fit |>
        purrr::chuck("model")

      flag_slope_warning <-
        list_slope_fit |>
        purrr::chuck("flag_warning")

      flag_slope_ok <-
        !base::is.null(mod_slope) &&
        !flag_slope_warning &&
        base::isTRUE(mod_slope[["converged"]]) &&
        base::length(stats::coef(mod_slope)) == 2L &&
        base::is.finite(stats::coef(mod_slope)[[2L]])

      if (
        flag_slope_ok
      ) {
        calibration_slope <-
          base::unname(stats::coef(mod_slope)[[2L]])
        slope_status <- "ok"
      } else if (
        flag_slope_warning
      ) {
        slope_status <- "undefined_fit_warning"
      } else {
        slope_status <- "undefined_fit_failure"
      }
    }
  }

  res <-
    tibble::tibble(
      calibration_intercept = calibration_intercept,
      calibration_slope = calibration_slope,
      intercept_status = intercept_status,
      slope_status = slope_status,
      n_observations = list_input |>
        purrr::chuck("n_observations"),
      n_presences = list_input |>
        purrr::chuck("n_presences"),
      n_absences = list_input |>
        purrr::chuck("n_absences"),
      prevalence = list_input |>
        purrr::chuck("prevalence"),
      epsilon = epsilon
    )

  return(res)
}

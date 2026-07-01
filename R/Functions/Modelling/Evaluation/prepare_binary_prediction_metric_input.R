#' @title Prepare Binary Prediction Metric Input
#' @description
#' Validates aligned binary observations and predicted probabilities and
#' computes counts shared by predictive metric evaluators.
#' @param observed
#' Numeric vector containing only zero and one.
#' @param predicted_probability
#' Numeric vector of predicted probabilities in the closed interval `[0, 1]`,
#' aligned one-to-one with `observed`.
#' @return
#' Named list containing validated observation and probability vectors,
#' observation counts, prevalence, and `class_status`. The status is `"ok"`,
#' `"undefined_no_presences"`, or `"undefined_no_absences"`.
#' @examples
#' prepare_binary_prediction_metric_input(
#'   observed = c(0, 1),
#'   predicted_probability = c(0.2, 0.8)
#' )
#' @export
prepare_binary_prediction_metric_input <- function(
    observed = NULL,
    predicted_probability = NULL) {
  assertthat::assert_that(
    base::is.numeric(observed),
    msg = "`observed` must be a numeric vector."
  )

  assertthat::assert_that(
    base::is.numeric(predicted_probability),
    msg = "`predicted_probability` must be a numeric vector."
  )

  assertthat::assert_that(
    base::length(observed) > 0L,
    base::length(observed) == base::length(predicted_probability),
    msg = stringr::str_c(
      "`observed` and `predicted_probability` must have the same",
      " ",
      "positive length."
    )
  )

  assertthat::assert_that(
    base::all(base::is.finite(observed)),
    msg = "`observed` must contain only finite values."
  )

  assertthat::assert_that(
    base::all(base::is.finite(predicted_probability)),
    msg = "`predicted_probability` must contain only finite values."
  )

  assertthat::assert_that(
    base::all(observed %in% base::c(0, 1)),
    msg = "`observed` must contain only zero and one."
  )

  assertthat::assert_that(
    base::all(
      predicted_probability >= 0 & predicted_probability <= 1
    ),
    msg = stringr::str_c(
      "`predicted_probability` must be in the closed interval",
      " ",
      "[0, 1]."
    )
  )

  vec_observed <-
    base::as.integer(observed)

  vec_predicted_probability <-
    base::as.numeric(predicted_probability)

  n_observations <-
    base::length(vec_observed)

  n_presences <-
    base::sum(vec_observed == 1L)

  n_absences <-
    n_observations - n_presences

  class_status <-
    dplyr::case_when(
      n_presences == 0L ~ "undefined_no_presences",
      n_absences == 0L ~ "undefined_no_absences",
      .default = "ok"
    )

  res <-
    base::list(
      observed = vec_observed,
      predicted_probability = vec_predicted_probability,
      n_observations = base::as.integer(n_observations),
      n_presences = base::as.integer(n_presences),
      n_absences = base::as.integer(n_absences),
      prevalence = n_presences / n_observations,
      class_status = class_status
    )

  return(res)
}

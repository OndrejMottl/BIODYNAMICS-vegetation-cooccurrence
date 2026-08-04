#' @title Evaluate Binary Log Loss
#' @description
#' Calculates mean binary cross-entropy after clipping probabilities away
#' from zero and one.
#' @param observed
#' Numeric binary observation vector.
#' @param predicted_probability
#' Numeric predicted-probability vector aligned with `observed`.
#' @param epsilon
#' Single numeric clipping tolerance strictly between zero and `0.5`.
#' Defaults to `1e-6`.
#' @return
#' One-row tibble containing `log_loss`, `metric_status`, observation counts,
#' prevalence, and the clipping tolerance. Valid one-class inputs retain a
#' finite log loss because this metric does not require both classes.
#' @examples
#' evaluate_binary_log_loss(
#'   observed = c(0, 1),
#'   predicted_probability = c(0.25, 0.75)
#' )
#' @export
evaluate_binary_log_loss <- function(
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

  vec_predicted_clipped <-
    base::pmin(
      base::pmax(vec_predicted_probability, epsilon),
      1 - epsilon
    )

  log_loss <-
    -base::mean(
      vec_observed * base::log(vec_predicted_clipped) +
        (1 - vec_observed) * base::log(1 - vec_predicted_clipped)
    )

  res <-
    tibble::tibble(
      log_loss = log_loss,
      metric_status = "ok",
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

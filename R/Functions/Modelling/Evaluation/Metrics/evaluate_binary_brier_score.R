#' @title Evaluate Binary Brier Score
#' @description
#' Calculates the mean squared error between binary observations and predicted
#' probabilities.
#' @param observed
#' Numeric binary observation vector.
#' @param predicted_probability
#' Numeric predicted-probability vector aligned with `observed`.
#' @return
#' One-row tibble containing `brier_score`, `metric_status`, observation counts,
#' and prevalence. Valid one-class inputs retain a finite Brier score because
#' this metric does not require both classes.
#' @examples
#' evaluate_binary_brier_score(
#'   observed = c(0, 1),
#'   predicted_probability = c(0.25, 0.75)
#' )
#' @export
evaluate_binary_brier_score <- function(
    observed = NULL,
    predicted_probability = NULL) {
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

  brier_score <-
    base::mean((vec_observed - vec_predicted_probability)^2)

  res <-
    tibble::tibble(
      brier_score = brier_score,
      metric_status = "ok",
      n_observations = list_input |>
        purrr::chuck("n_observations"),
      n_presences = list_input |>
        purrr::chuck("n_presences"),
      n_absences = list_input |>
        purrr::chuck("n_absences"),
      prevalence = list_input |>
        purrr::chuck("prevalence")
    )

  return(res)
}

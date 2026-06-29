#' @title Evaluate Tjur R-Squared
#' @description
#' Calculates Tjur's coefficient of discrimination from binary observations
#' and predicted probabilities.
#' @param observed
#' Numeric binary observation vector.
#' @param predicted_probability
#' Numeric predicted-probability vector aligned with `observed`.
#' @return
#' One-row tibble containing `tjur_r2`, `metric_status`, observation counts,
#' and prevalence. Tjur R-squared is `NA` when either response class is absent.
#' Negative values are retained.
#' @examples
#' evaluate_tjur_r2(
#'   observed = c(0, 0, 1, 1),
#'   predicted_probability = c(0.1, 0.3, 0.6, 0.8)
#' )
#' @export
evaluate_tjur_r2 <- function(
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

  metric_status <-
    list_input |>
    purrr::chuck("class_status")

  tjur_r2 <-
    if (
      metric_status == "ok"
    ) {
      base::mean(vec_predicted_probability[vec_observed == 1L]) -
        base::mean(vec_predicted_probability[vec_observed == 0L])
    } else {
      NA_real_
    }

  res <-
    tibble::tibble(
      tjur_r2 = tjur_r2,
      metric_status = metric_status,
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

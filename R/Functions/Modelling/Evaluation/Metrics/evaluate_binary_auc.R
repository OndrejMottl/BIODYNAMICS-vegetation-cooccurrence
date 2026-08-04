#' @title Evaluate Binary AUC
#' @description
#' Calculates area under the receiver operating characteristic curve from
#' binary observations and predicted probabilities using average ranks.
#' @param observed
#' Numeric binary observation vector.
#' @param predicted_probability
#' Numeric predicted-probability vector aligned with `observed`.
#' @return
#' One-row tibble containing `auc`, `metric_status`, observation counts, and
#' prevalence. AUC is `NA` when either response class is absent.
#' @examples
#' evaluate_binary_auc(
#'   observed = c(0, 0, 1, 1),
#'   predicted_probability = c(0.1, 0.3, 0.6, 0.8)
#' )
#' @export
evaluate_binary_auc <- function(
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

  n_presences <-
    list_input |>
    purrr::chuck("n_presences")

  n_absences <-
    list_input |>
    purrr::chuck("n_absences")

  metric_status <-
    list_input |>
    purrr::chuck("class_status")

  auc <-
    if (
      metric_status == "ok"
    ) {
      vec_probability_ranks <-
        base::rank(
          vec_predicted_probability,
          ties.method = "average"
        )

      rank_sum_presences <-
        base::sum(vec_probability_ranks[vec_observed == 1L])

      (rank_sum_presences -
        n_presences * (n_presences + 1L) / 2) /
        (n_presences * n_absences)
    } else {
      NA_real_
    }

  res <-
    tibble::tibble(
      auc = auc,
      metric_status = metric_status,
      n_observations = list_input |>
        purrr::chuck("n_observations"),
      n_presences = n_presences,
      n_absences = n_absences,
      prevalence = list_input |>
        purrr::chuck("prevalence")
    )

  return(res)
}

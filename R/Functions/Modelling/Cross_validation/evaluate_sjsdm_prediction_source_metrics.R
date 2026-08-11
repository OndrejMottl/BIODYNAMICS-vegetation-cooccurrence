#' @title Evaluate One sjSDM Fold Prediction Source
#' @description
#' Computes the registered binary metrics for one model or prevalence-null
#' probability vector, including typed incomplete rows.
#' @param vec_observed,vec_probability
#' Binary observations and aligned probabilities.
#' @param prediction_source
#' Source identifier stored in every metric row.
#' @param flag_complete
#' Logical indicating whether probabilities are complete.
#' @param incomplete_status
#' Status used for typed incomplete metric rows.
#' @param epsilon
#' Probability clipping tolerance for log loss and calibration.
#' @return
#' Six-row source-metric tibble.
#' @export
evaluate_sjsdm_prediction_source_metrics <- function(
    vec_observed = NULL,
    vec_probability = NULL,
    prediction_source = NULL,
    flag_complete = NULL,
    incomplete_status = NULL,
    epsilon = 1e-6) {
  assertthat::assert_that(
    base::is.numeric(vec_observed),
    base::is.numeric(vec_probability),
    base::length(vec_observed) == base::length(vec_probability),
    base::is.character(prediction_source),
    base::length(prediction_source) == 1L,
    base::is.logical(flag_complete),
    base::length(flag_complete) == 1L,
    !base::is.na(flag_complete),
    base::is.character(incomplete_status),
    base::length(incomplete_status) == 1L,
    msg = "Prediction-source metric inputs are incomplete."
  )

  n_observations <-
    base::length(vec_observed)

  n_presences <-
    base::sum(vec_observed == 1)

  n_absences <-
    n_observations - n_presences

  prevalence <-
    n_presences / n_observations

  if (
    !flag_complete
  ) {
    res_incomplete <-
      tibble::tibble(
        prediction_source = prediction_source,
        metric_id = base::c(
          "tjur_r2",
          "auc",
          "log_loss",
          "brier_score",
          "calibration_intercept",
          "calibration_slope"
        ),
        estimate = NA_real_,
        metric_status = incomplete_status,
        n_observations = base::as.integer(n_observations),
        n_presences = base::as.integer(n_presences),
        n_absences = base::as.integer(n_absences),
        prevalence = prevalence
      )

    return(res_incomplete)
  }

  data_tjur <-
    evaluate_tjur_r2(
      observed = vec_observed,
      predicted_probability = vec_probability
    ) |>
    dplyr::mutate(
      metric_id = "tjur_r2",
      estimate = .data[["tjur_r2"]]
    ) |>
    dplyr::select(
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    )

  data_auc <-
    evaluate_binary_auc(
      observed = vec_observed,
      predicted_probability = vec_probability
    ) |>
    dplyr::mutate(
      metric_id = "auc",
      estimate = .data[["auc"]]
    ) |>
    dplyr::select(
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    )

  data_log_loss <-
    evaluate_binary_log_loss(
      observed = vec_observed,
      predicted_probability = vec_probability,
      epsilon = epsilon
    ) |>
    dplyr::mutate(
      metric_id = "log_loss",
      estimate = .data[["log_loss"]]
    ) |>
    dplyr::select(
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    )

  data_brier_score <-
    evaluate_binary_brier_score(
      observed = vec_observed,
      predicted_probability = vec_probability
    ) |>
    dplyr::mutate(
      metric_id = "brier_score",
      estimate = .data[["brier_score"]]
    ) |>
    dplyr::select(
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    )

  data_calibration <-
    evaluate_binary_calibration(
      observed = vec_observed,
      predicted_probability = vec_probability,
      epsilon = epsilon
    )

  data_calibration_metrics <-
    tibble::tibble(
      metric_id = base::c(
        "calibration_intercept",
        "calibration_slope"
      ),
      estimate = base::c(
        data_calibration[["calibration_intercept"]],
        data_calibration[["calibration_slope"]]
      ),
      metric_status = base::c(
        data_calibration[["intercept_status"]],
        data_calibration[["slope_status"]]
      ),
      n_observations = data_calibration[["n_observations"]],
      n_presences = data_calibration[["n_presences"]],
      n_absences = data_calibration[["n_absences"]],
      prevalence = data_calibration[["prevalence"]]
    )

  res <-
    base::list(
      data_tjur,
      data_auc,
      data_log_loss,
      data_brier_score,
      data_calibration_metrics
    ) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      prediction_source = prediction_source,
      .before = 1L
    )

  return(res)
}

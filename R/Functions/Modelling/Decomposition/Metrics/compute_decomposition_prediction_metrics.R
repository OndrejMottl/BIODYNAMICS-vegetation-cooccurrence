#' @title Compute Decomposition Prediction Metrics
#' @description
#' Computes held-out binary prediction metrics for diagnostic models.
#' @param data_observed
#' Observed test response matrix.
#' @param data_predicted
#' Predicted probability matrix aligned to `data_observed`.
#' @return
#' One-row tibble with log-loss, Brier, pooled AUC, and macro-AUC.
#' @export
compute_decomposition_prediction_metrics <- function(
    data_observed = NULL,
    data_predicted = NULL) {
  assertthat::assert_that(
    base::is.matrix(data_observed),
    msg = "`data_observed` must be a matrix."
  )

  assertthat::assert_that(
    base::is.matrix(data_predicted),
    msg = "`data_predicted` must be a matrix."
  )

  assertthat::assert_that(
    base::all(base::dim(data_observed) == base::dim(data_predicted)),
    msg = "`data_observed` and `data_predicted` dimensions must match."
  )

  if (
    base::is.null(base::colnames(data_predicted))
  ) {
    base::colnames(data_predicted) <- base::colnames(data_observed)
  }

  data_predicted_clipped <-
    base::pmin(
      base::pmax(data_predicted, 1e-6),
      1 - 1e-6
    )

  loss <-
    -base::mean(
      data_observed * base::log(data_predicted_clipped) +
        (1 - data_observed) * base::log(1 - data_predicted_clipped)
    )

  brier <-
    base::mean((data_observed - data_predicted_clipped)^2)

  vec_observed <-
    base::as.numeric(data_observed)

  vec_predicted <-
    base::as.numeric(data_predicted_clipped)

  auc <-
    if (
      base::length(base::unique(vec_observed)) == 2L
    ) {
      Metrics::auc(
        actual = vec_observed,
        predicted = vec_predicted
      )
    } else {
      NA_real_
    }

  vec_auc_species <-
    base::colnames(data_observed) |>
    purrr::map_dbl(
      .f = ~ {
        vec_observed_species <-
          data_observed[, .x]

        if (
          base::length(base::unique(vec_observed_species)) != 2L
        ) {
          return(NA_real_)
        }

        Metrics::auc(
          actual = vec_observed_species,
          predicted = data_predicted_clipped[, .x]
        )
      }
    )

  auc_macro <-
    if (
      base::all(base::is.na(vec_auc_species))
    ) {
      NA_real_
    } else {
      base::mean(vec_auc_species, na.rm = TRUE)
    }

  res <-
    tibble::tibble(
      loss = loss,
      brier = brier,
      auc = auc,
      auc_macro = auc_macro
    )

  return(res)
}

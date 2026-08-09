#' @title Evaluate JSDM Model Performance
#' @description
#' Evaluates a fitted sjSDM model and returns comprehensive performance
#' metrics at both model and species level.
#' @param mod_jsdm
#' A fitted sjSDM model object. Must be of class 'sjSDM'.
#' @return
#' A list with three elements:
#' - `vec_model_metrics`: Named numeric vector of R-squared values
#'   (McFadden, Nagelkerke)
#' - `data_taxon_metrics`: A tibble with one row per taxon and columns:
#'   `taxon_name`, `auc`, `accuracy`, `log_loss` (binomial) or `rmse` (other
#'   families)
#' - `list_convergence_diagnostics`: A list from
#'   [diagnose_jsdm_convergence()] with
#'   `linear_trend_slope`, `median_diff`, `convergence_plot`, and
#'   `note`
#' @details
#' For binomial models, species-level classification metrics (AUC,
#' Accuracy, LogLoss) are computed using a 0.5 probability threshold
#' for binary predictions. For other model families, RMSE is computed
#' per species.
#'
#' Convergence is assessed via [diagnose_jsdm_convergence()], which
#' analyses the training loss history. A `linear_trend_slope` < 0.01
#' and `median_diff` < 1 in the returned `convergence` element
#' indicate that the model has converged.
#' @seealso sjSDM::Rsquared, Metrics::auc, diagnose_jsdm_convergence
#' @export
evaluate_jsdm <- function(mod_jsdm = NULL) {
  assertthat::assert_that(
    base::inherits(mod_jsdm, "sjSDM"),
    msg = "mod_jsdm must be of class sjSDM"
  )

  # Extract observed and predicted values
  obs_data <-
    mod_jsdm |>
    purrr::chuck("data") |>
    purrr::chuck("Y")

  pred_prob <-
    stats::predict(mod_jsdm, newdata = NULL)

  vec_species <-
    base::seq_len(base::ncol(obs_data)) |>
    rlang::set_names(base::colnames(obs_data))

  # 1. R-squared metrics
  # Note: sjSDM::Rsquared() prints to console regardless of verbose = FALSE;
  #   capture.output() suppresses this unwanted output.
  invisible(
    utils::capture.output(
      vec_r2 <- base::c(
        sjSDM::Rsquared(mod_jsdm, method = "McFadden", verbose = FALSE),
        sjSDM::Rsquared(mod_jsdm, method = "Nagelkerke", verbose = FALSE)
      )
    )
  )

  vec_model_metrics <-
    rlang::set_names(
      vec_r2,
      base::c("r2_mcfadden", "r2_nagelkerke")
    )

  # 2. Species-level metrics
  family_name <-
    mod_jsdm |>
    purrr::chuck("family") |>
    purrr::chuck("family") |>
    purrr::chuck("family")

  if (
    family_name == "binomial"
  ) {
    # AUC per species
    vec_auc <-
      vec_species |>
      purrr::map_dbl(
        ~ Metrics::auc(
          actual = obs_data[, .x],
          predicted = pred_prob[, .x]
        )
      )

    # Accuracy per species (binary predictions at 0.5 threshold)
    pred_binary <- pred_prob > 0.5

    vec_accuracy <-
      vec_species |>
      purrr::map_dbl(
        ~ Metrics::accuracy(
          actual = obs_data[, .x],
          predicted = pred_binary[, .x]
        )
      )

    # Log Loss per species
    vec_logloss <-
      vec_species |>
      purrr::map_dbl(
        ~ Metrics::logLoss(
          actual = obs_data[, .x],
          predicted = pred_prob[, .x]
        )
      )

    data_taxon_metrics <-
      tibble::tibble(
        taxon_name = base::colnames(obs_data),
        auc = vec_auc,
        accuracy = vec_accuracy,
        log_loss = vec_logloss
      )
  } else {
    # For non-binomial models, use RMSE
    vec_rmse <-
      vec_species |>
      purrr::map_dbl(
        ~ base::sqrt(
          base::mean((obs_data[, .x] - pred_prob[, .x])^2)
        )
      )

    data_taxon_metrics <-
      tibble::tibble(
        taxon_name = base::colnames(obs_data),
        rmse = vec_rmse
      )
  }

  # 3. Convergence diagnostics
  list_convergence_diagnostics <-
    diagnose_jsdm_convergence(mod_jsdm)

  res <-
    base::list(
      vec_model_metrics = vec_model_metrics,
      data_taxon_metrics = data_taxon_metrics,
      list_convergence_diagnostics = list_convergence_diagnostics
    )

  return(res)
}

#' @title Evaluate JSDM Model Performance
#' @description
#' Evaluates a fitted sjSDM model and returns comprehensive performance
#' metrics at both model and species level.
#' @param mod_jsdm
#' A fitted sjSDM model object. Must be of class 'sjSDM'.
#' @return
#' A list with two elements:
#' - model: Named numeric vector of R-squared values (McFadden, Nagelkerke)
#' - species: A tibble with one row per species and columns:
#'   species, AUC, Accuracy, LogLoss (binomial) or RMSE (other families)
#' @details
#' For binomial models, species-level classification metrics (AUC, Accuracy,
#' LogLoss) are computed using a 0.5 probability threshold for binary
#' predictions. For other model families, RMSE is computed per species.
#' @seealso sjSDM::Rsquared, Metrics::auc
#' @export
evaluate_jsdm <- function(mod_jsdm = NULL) {
  assertthat::assert_that(
    inherits(mod_jsdm, "sjSDM"),
    msg = "mod_jsdm must be of class sjSDM"
  )

  # Extract observed and predicted values
  obs_data <-
    mod_jsdm$data$Y
  pred_prob <-
    predict(mod_jsdm, newdata = NULL)

  vec_species <-
    seq_len(ncol(obs_data)) |>
    rlang::set_names(colnames(obs_data))

  # Initialize evaluation list
  list_eval <-
    list(
      model = NULL,
      species = NULL
    )

  # 1. R-squared metrics
  # Note: sjSDM::Rsquared() prints to console regardless of verbose = FALSE;
  #   capture.output() suppresses this unwanted output.
  invisible(
    utils::capture.output(
      vec_r2 <- c(
        sjSDM::Rsquared(mod_jsdm, method = "McFadden", verbose = FALSE),
        sjSDM::Rsquared(mod_jsdm, method = "Nagelkerke", verbose = FALSE)
      )
    )
  )

  list_eval$model <-
    rlang::set_names(vec_r2, c("R2-McFadden", "R2-Nagelkerke"))

  # 2. Species-level metrics
  if (
    mod_jsdm$family$family$family == "binomial"
  ) {
    # AUC per species
    vec_auc <-
      vec_species |>
      purrr::map_dbl(
        ~ Metrics::auc(
          actual = as.data.frame(obs_data)[, .x],
          predicted = as.data.frame(pred_prob)[, .x]
        )
      )

    # Accuracy per species (binary predictions at 0.5 threshold)
    pred_binary <- pred_prob > 0.5

    vec_accuracy <-
      vec_species |>
      purrr::map_dbl(
        ~ Metrics::accuracy(
          actual = as.data.frame(obs_data)[, .x],
          predicted = as.data.frame(pred_binary)[, .x]
        )
      )

    # Log Loss per species
    vec_logloss <-
      vec_species |>
      purrr::map_dbl(
        ~ Metrics::logLoss(
          actual = as.data.frame(obs_data)[, .x],
          predicted = as.data.frame(pred_prob)[, .x]
        )
      )

    list_eval$species <-
      tibble::tibble(
        species = colnames(obs_data),
        AUC = vec_auc,
        Accuracy = vec_accuracy,
        LogLoss = vec_logloss
      )
  } else {
    # For non-binomial models, use RMSE
    vec_rmse <-
      vec_species |>
      purrr::map_dbl(
        ~ sqrt(mean((obs_data[, .x] - pred_prob[, .x])^2))
      )

    list_eval$species <-
      tibble::tibble(
        species = colnames(obs_data),
        RMSE = vec_rmse
      )
  }

  return(list_eval)
}

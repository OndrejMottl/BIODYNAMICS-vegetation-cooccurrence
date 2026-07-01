#' @title Score sjSDM Tuning Predictions
#' @description
#' Calculates compact held-out binomial tuning metrics from aligned observed
#' and predicted matrices.
#' @param data_observed
#' Binary numeric matrix of held-out observations.
#' @param data_predicted
#' Numeric matrix of held-out probabilities with matching dimensions and
#' dimnames. Missing prediction dimnames inherit observation dimnames.
#' @param epsilon
#' Probability clipping tolerance strictly between zero and `0.5`.
#' @return
#' One-row tibble with retained taxa, response-value count, total and
#' per-response negative log likelihood, and macro AUC.
#' @export
score_sjsdm_tuning_predictions <- function(
    data_observed = NULL,
    data_predicted = NULL,
    epsilon = 1e-6) {
  assertthat::assert_that(
    base::is.matrix(data_observed),
    base::is.numeric(data_observed),
    base::nrow(data_observed) > 0L,
    base::ncol(data_observed) > 0L,
    msg = "`data_observed` must be a numeric matrix."
  )

  assertthat::assert_that(
    base::is.matrix(data_predicted) ||
      base::is.data.frame(data_predicted),
    msg = "`data_predicted` must be matrix-like."
  )

  flag_valid_epsilon <-
    base::is.numeric(epsilon) &&
    base::length(epsilon) == 1L &&
    base::is.finite(epsilon) &&
    epsilon > 0 &&
    epsilon < 0.5

  assertthat::assert_that(
    flag_valid_epsilon,
    msg = "`epsilon` must be a finite number between zero and 0.5."
  )

  data_predicted_matrix <-
    base::as.matrix(data_predicted)

  assertthat::assert_that(
    base::is.numeric(data_predicted_matrix),
    msg = "`data_predicted` must contain numeric probabilities."
  )

  if (
    base::is.null(base::rownames(data_predicted_matrix))
  ) {
    base::rownames(data_predicted_matrix) <-
      base::rownames(data_observed)
  }

  if (
    base::is.null(base::colnames(data_predicted_matrix))
  ) {
    base::colnames(data_predicted_matrix) <-
      base::colnames(data_observed)
  }

  if (
    !base::all(
      base::dim(data_predicted_matrix) == base::dim(data_observed)
    ) ||
      !base::all(base::is.finite(data_predicted_matrix)) ||
      base::any(data_predicted_matrix < 0) ||
      base::any(data_predicted_matrix > 1) ||
      !base::all(data_observed %in% base::c(0, 1)) ||
      !base::identical(
        base::rownames(data_predicted_matrix),
        base::rownames(data_observed)
      ) ||
      !base::identical(
        base::colnames(data_predicted_matrix),
        base::colnames(data_observed)
      )
  ) {
    cli::cli_abort("Observed and predicted matrices are not aligned.")
  }

  data_predicted_clipped <-
    base::pmin(
      base::pmax(data_predicted_matrix, epsilon),
      1 - epsilon
    )

  negative_log_likelihood_test <-
    -base::sum(
      data_observed * base::log(data_predicted_clipped) +
        (1 - data_observed) * base::log(1 - data_predicted_clipped)
    )

  vec_auc <-
    base::seq_len(base::ncol(data_observed)) |>
    purrr::map_dbl(
      .f = ~ {
        evaluate_binary_auc(
          observed = data_observed[, .x],
          predicted_probability = data_predicted_clipped[, .x]
        )[["auc"]][[1L]]
      }
    )

  auc_macro_test <-
    if (
      base::all(base::is.na(vec_auc))
    ) {
      NA_real_
    } else {
      base::mean(vec_auc, na.rm = TRUE)
    }

  res <-
    tibble::tibble(
      n_taxa_retained = base::ncol(data_observed),
      n_response_values = base::length(data_observed),
      negative_log_likelihood_test = negative_log_likelihood_test,
      negative_log_likelihood_per_response =
        negative_log_likelihood_test / base::length(data_observed),
      auc_macro_test = auc_macro_test
    )

  return(res)
}

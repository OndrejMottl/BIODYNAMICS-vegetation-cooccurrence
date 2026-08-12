#' @title Build One sjSDM Candidate-Fold Result
#' @description
#' Constructs one typed tuning row and its compact prediction-cache record for
#' a completed or failed candidate lifecycle.
#' @param data_candidate
#' One-row candidate table with the candidate identifier and six parameters.
#' @param list_fold_context
#' Fold context containing identifiers, sizes, and the CV strategy.
#' @param fit_seed,score_seed
#' Derived candidate seeds, or typed missing integers before candidate work.
#' @param fit_status
#' One of `preparation_error`, `fit_error`, `prediction_error`,
#' `scoring_error`, or `ok`.
#' @param error_message
#' Character failure message, or a missing character value for success.
#' @param data_metrics
#' Optional named list of the five candidate scoring metrics.
#' @param data_predicted
#' Optional held-out probability matrix. Fitted model objects are never stored.
#' @param fit_seconds,prediction_seconds,scoring_seconds
#' Candidate lifecycle timings in seconds.
#' @return
#' Named list containing one-row `data_tuning` and `list_prediction`.
#' @export
build_sjsdm_candidate_fold_result <- function(
    data_candidate = NULL,
    list_fold_context = NULL,
    fit_seed = NA_integer_,
    score_seed = NA_integer_,
    fit_status = NULL,
    error_message = NA_character_,
    data_metrics = NULL,
    data_predicted = NULL,
    fit_seconds = NA_real_,
    prediction_seconds = NA_real_,
    scoring_seconds = NA_real_) {
  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_candidate_columns <-
    base::c("candidate_id", vec_parameter_columns)

  vec_context_names <-
    base::c(
      "repeat_id",
      "fold_id",
      "n_train_locations",
      "n_test_locations",
      "n_train_samples",
      "n_test_samples",
      "cv_strategy"
    )

  vec_statuses <-
    base::c(
      "preparation_error",
      "fit_error",
      "prediction_error",
      "scoring_error",
      "ok"
    )

  vec_metric_names <-
    base::c(
      "n_taxa_retained",
      "n_response_values",
      "negative_log_likelihood_test",
      "negative_log_likelihood_per_response",
      "auc_macro_test"
    )

  assertthat::assert_that(
    base::is.data.frame(data_candidate),
    base::nrow(data_candidate) == 1L,
    base::all(vec_candidate_columns %in% base::colnames(data_candidate)),
    base::is.list(list_fold_context),
    base::all(vec_context_names %in% base::names(list_fold_context)),
    msg = "Candidate-fold result inputs are incomplete."
  )

  assertthat::assert_that(
    base::is.character(fit_status),
    base::length(fit_status) == 1L,
    fit_status %in% vec_statuses,
    msg = "fit_status is not a registered candidate lifecycle status."
  )

  if (
    fit_status == "ok"
  ) {
    assertthat::assert_that(
      base::is.list(data_metrics),
      base::all(vec_metric_names %in% base::names(data_metrics)),
      msg = "Successful candidate metrics are incomplete."
    )
  }

  list_metrics <-
    if (
      base::is.null(data_metrics)
    ) {
      base::list(
        n_taxa_retained = NA_integer_,
        n_response_values = NA_integer_,
        negative_log_likelihood_test = NA_real_,
        negative_log_likelihood_per_response = NA_real_,
        auc_macro_test = NA_real_
      )
    } else {
      data_metrics
    }

  data_tuning <-
    data_candidate |>
    dplyr::mutate(
      repeat_id = list_fold_context[["repeat_id"]],
      fold_id = list_fold_context[["fold_id"]],
      fit_seed = fit_seed,
      score_seed = score_seed,
      n_train_locations =
        list_fold_context[["n_train_locations"]],
      n_test_locations =
        list_fold_context[["n_test_locations"]],
      n_train_samples =
        list_fold_context[["n_train_samples"]],
      n_test_samples =
        list_fold_context[["n_test_samples"]],
      n_taxa_retained = list_metrics[["n_taxa_retained"]],
      n_response_values = list_metrics[["n_response_values"]],
      negative_log_likelihood_test =
        list_metrics[["negative_log_likelihood_test"]],
      negative_log_likelihood_per_response =
        list_metrics[["negative_log_likelihood_per_response"]],
      auc_macro_test = list_metrics[["auc_macro_test"]],
      fit_status = fit_status,
      error_message = error_message,
      cv_strategy = list_fold_context[["cv_strategy"]],
      regularization_source = "unit_cv",
      .before = 1L
    ) |>
    dplyr::select(
      "repeat_id",
      "fold_id",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
      "fit_seed",
      "score_seed",
      "n_train_locations",
      "n_test_locations",
      "n_train_samples",
      "n_test_samples",
      "n_taxa_retained",
      "n_response_values",
      "negative_log_likelihood_test",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "fit_status",
      "error_message",
      "cv_strategy",
      "regularization_source"
    )

  res <-
    base::list(
      data_tuning = data_tuning,
      list_prediction = base::list(
        candidate_id = data_candidate[["candidate_id"]][[1L]],
        fit_seed = fit_seed,
        fit_status = fit_status,
        error_message = error_message,
        data_predicted = if (
          base::is.null(data_predicted)
        ) {
          NULL
        } else {
          base::as.matrix(data_predicted)
        },
        fit_seconds = fit_seconds,
        prediction_seconds = prediction_seconds,
        scoring_seconds = scoring_seconds
      )
    )

  return(res)
}

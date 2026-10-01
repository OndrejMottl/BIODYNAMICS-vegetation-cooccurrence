#' @title Build an Empty sjSDM Tuning Result
#' @description
#' Constructs the typed empty tuning table and prediction cache used when no
#' candidate-fold work item is applicable.
#' @return
#' Named list with `data_tuning` and `list_prediction_cache`.
#' @export
#' @examples
#' build_sjsdm_empty_tuning_result()
build_sjsdm_empty_tuning_result <- function() {
  res <-
    base::list(
      data_tuning = tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        candidate_id = base::character(),
        alpha_cov = base::numeric(),
        alpha_coef = base::numeric(),
        alpha_spatial = base::numeric(),
        lambda_cov = base::numeric(),
        lambda_coef = base::numeric(),
        lambda_spatial = base::numeric(),
        fit_seed = base::integer(),
        score_seed = base::integer(),
        n_train_locations = base::integer(),
        n_test_locations = base::integer(),
        n_train_samples = base::integer(),
        n_test_samples = base::integer(),
        n_taxa_retained = base::integer(),
        n_response_values = base::integer(),
        negative_log_likelihood_test = base::numeric(),
        negative_log_likelihood_per_response = base::numeric(),
        auc_macro_test = base::numeric(),
        converged = base::logical(),
        actual_n_iter = base::integer(),
        actual_n_sampling = base::integer(),
        epochs_run = base::integer(),
        linear_trend_slope = base::numeric(),
        median_diff = base::numeric(),
        early_stopping_triggered = base::logical(),
        fit_status = base::character(),
        error_message = base::character(),
        cv_strategy = base::character(),
        regularization_source = base::character()
      ),
      list_prediction_cache = base::list()
    )

  return(res)
}

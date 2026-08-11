testthat::test_that(
  "build_sjsdm_empty_tuning_result() preserves the typed schema",
  {
    res <-
      build_sjsdm_empty_tuning_result()

    testthat::expect_named(
      res,
      base::c("data_tuning", "list_prediction_cache")
    )
    testthat::expect_equal(base::nrow(res[["data_tuning"]]), 0L)
    testthat::expect_length(res[["list_prediction_cache"]], 0L)
    testthat::expect_named(
      res[["data_tuning"]],
      base::c(
        "repeat_id",
        "fold_id",
        "candidate_id",
        "alpha_cov",
        "alpha_coef",
        "alpha_spatial",
        "lambda_cov",
        "lambda_coef",
        "lambda_spatial",
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
    )
    testthat::expect_identical(
      purrr::map_chr(res[["data_tuning"]], base::typeof),
      base::c(
        repeat_id = "integer",
        fold_id = "integer",
        candidate_id = "character",
        alpha_cov = "double",
        alpha_coef = "double",
        alpha_spatial = "double",
        lambda_cov = "double",
        lambda_coef = "double",
        lambda_spatial = "double",
        fit_seed = "integer",
        score_seed = "integer",
        n_train_locations = "integer",
        n_test_locations = "integer",
        n_train_samples = "integer",
        n_test_samples = "integer",
        n_taxa_retained = "integer",
        n_response_values = "integer",
        negative_log_likelihood_test = "double",
        negative_log_likelihood_per_response = "double",
        auc_macro_test = "double",
        fit_status = "character",
        error_message = "character",
        cv_strategy = "character",
        regularization_source = "character"
      )
    )
  }
)

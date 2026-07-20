testthat::test_that(
  "run_sjsdm_tuning_fold_candidates() retains preparation errors",
  {
    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    list_fold_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 2L,
        train_indices = base::c(1L, 2L),
        test_indices = base::c(3L, 4L),
        n_train_locations = 2L,
        n_test_locations = 2L,
        n_train_samples = 2L,
        n_test_samples = 2L,
        cv_strategy = "spatially_stratified_group_kfold"
      )

    prepare_fold_function <- function(...) {
      base::stop("fold preparation failed")
    }

    fit_function <- function(...) {
      base::stop("fit must not run")
    }

    predict_function <- function(...) {
      base::stop("prediction must not run")
    }

    res <-
      run_sjsdm_tuning_fold_candidates(
        data_candidates = data_candidates,
        list_fold_context = list_fold_context,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true(
      base::all(res[["fit_status"]] == "preparation_error")
    )
    testthat::expect_match(
      res[["error_message"]],
      "fold preparation failed",
      all = TRUE
    )
  }
)

testthat::test_that(
  "run_sjsdm_tuning_fold_candidates() retains downstream errors",
  {
    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    list_fold_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 2L,
        train_indices = base::c(1L, 2L),
        test_indices = base::c(3L, 4L),
        n_train_locations = 2L,
        n_test_locations = 2L,
        n_train_samples = 2L,
        n_test_samples = 2L,
        cv_strategy = "spatially_stratified_group_kfold"
      )

    data_observed <-
      base::matrix(
        data = base::c(0, 1, 1, 0),
        nrow = 2L,
        dimnames = base::list(
          base::c("sample_3", "sample_4"),
          base::c("taxon_a", "taxon_b")
        )
      )

    prepare_fold_function <- function(...) {
      return(
        base::list(
          data_train_input = base::list(),
          data_test_input = base::list(),
          data_test_observed = data_observed
        )
      )
    }

    fit_function <- function(data_train_input, candidate, seed) {
      return(
        base::list(candidate_id = candidate[["candidate_id"]][[1L]])
      )
    }

    expected_columns <-
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

    metric_columns <-
      base::c(
        "n_taxa_retained",
        "n_response_values",
        "negative_log_likelihood_test",
        "negative_log_likelihood_per_response",
        "auc_macro_test"
      )

    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["score_count"]] <-
      0L

    predict_error_function <- function(...) {
      base::stop("prediction backend failed")
    }

    score_must_not_run <- function(...) {
      environment_calls[["score_count"]] <-
        environment_calls[["score_count"]] + 1L

      base::stop("score must not run")
    }

    data_prediction_errors <-
      run_sjsdm_tuning_fold_candidates(
        data_candidates = data_candidates,
        list_fold_context = list_fold_context,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_error_function,
        score_function = score_must_not_run
      )

    testthat::expect_named(data_prediction_errors, expected_columns)
    testthat::expect_identical(
      data_prediction_errors[["fit_status"]],
      base::rep("prediction_error", 2L)
    )
    testthat::expect_identical(
      data_prediction_errors[["error_message"]],
      base::rep("prediction backend failed", 2L)
    )
    testthat::expect_true(
      base::all(
        base::is.na(
          base::as.matrix(data_prediction_errors[metric_columns])
        )
      )
    )
    testthat::expect_true(
      base::all(!base::is.na(data_prediction_errors[["fit_seed"]]))
    )
    testthat::expect_true(
      base::all(!base::is.na(data_prediction_errors[["score_seed"]]))
    )
    testthat::expect_identical(environment_calls[["score_count"]], 0L)

    predict_function <- function(...) {
      return(data_observed * 0.8 + 0.1)
    }

    score_error_function <- function(...) {
      base::stop("scoring backend failed")
    }

    data_scoring_errors <-
      run_sjsdm_tuning_fold_candidates(
        data_candidates = data_candidates,
        list_fold_context = list_fold_context,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_error_function
      )

    testthat::expect_named(data_scoring_errors, expected_columns)
    testthat::expect_identical(
      data_scoring_errors[["fit_status"]],
      base::rep("scoring_error", 2L)
    )
    testthat::expect_identical(
      data_scoring_errors[["error_message"]],
      base::rep("scoring backend failed", 2L)
    )
    testthat::expect_true(
      base::all(
        base::is.na(
          base::as.matrix(data_scoring_errors[metric_columns])
        )
      )
    )
    testthat::expect_true(
      base::all(!base::is.na(data_scoring_errors[["fit_seed"]]))
    )
    testthat::expect_true(
      base::all(!base::is.na(data_scoring_errors[["score_seed"]]))
    )
  }
)

testthat::test_that(
  "run_sjsdm_tuning_fold_candidates() retains compact predictions",
  {
    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    list_fold_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 1L,
        train_indices = base::c(1L, 2L),
        test_indices = base::c(3L, 4L),
        n_train_locations = 2L,
        n_test_locations = 2L,
        n_train_samples = 2L,
        n_test_samples = 2L,
        cv_strategy = "spatially_stratified_group_kfold"
      )

    data_observed <-
      base::matrix(
        data = base::c(0, 1, 1, 0),
        nrow = 2L,
        dimnames = base::list(
          base::c("sample_3", "sample_4"),
          base::c("taxon_a", "taxon_b")
        )
      )

    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["prepare_count"]] <- 0L

    prepare_fold_function <- function(...) {
      environment_calls[["prepare_count"]] <-
        environment_calls[["prepare_count"]] + 1L

      return(
        base::list(
          data_train_input = base::list(),
          data_test_input = base::list(),
          data_train_observed = data_observed,
          data_test_observed = data_observed,
          data_test_observed_full = data_observed,
          test_sample_ids = base::rownames(data_observed),
          data_taxa_mapping = tibble::tibble(
            taxon = base::colnames(data_observed),
            retained = TRUE,
            status = "retained"
          )
        )
      )
    }

    fit_function <- function(data_train_input, candidate, seed) {
      return(candidate)
    }

    predict_function <- function(object, data_test_input) {
      return(data_observed * 0.8 + 0.1)
    }

    score_function <- function(
        object,
        data_test_input,
        data_observed,
        data_predicted,
        epsilon,
        score_seed) {
      return(
        base::list(
          n_taxa_retained = 2L,
          n_response_values = 4L,
          negative_log_likelihood_test = 1,
          negative_log_likelihood_per_response = 0.25,
          auc_macro_test = 1
        )
      )
    }

    list_result <-
      run_sjsdm_tuning_fold_candidates(
        data_candidates = data_candidates,
        list_fold_context = list_fold_context,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        retain_prediction_cache = TRUE
      )

    testthat::expect_named(
      list_result,
      base::c("data_tuning", "list_prediction_cache")
    )
    testthat::expect_identical(
      environment_calls[["prepare_count"]],
      1L
    )
    testthat::expect_length(
      list_result[["list_prediction_cache"]][[
        "list_candidate_predictions"
      ]],
      2L
    )
    testthat::expect_true(
      base::all(
        purrr::map_lgl(
          list_result[["list_prediction_cache"]][[
            "list_candidate_predictions"
          ]],
          ~ base::is.matrix(.x[["data_predicted"]])
        )
      )
    )
  }
)

testthat::test_that(
  "run_sjsdm_prepared_tuning_candidate() returns exact outputs",
  {
    data_candidate <-
      tibble::tibble(
        candidate_id = "candidate_1",
        alpha_cov = 0,
        alpha_coef = 0,
        alpha_spatial = 0,
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1
      )

    data_observed <-
      base::matrix(
        data = base::c(0, 1, 1, 0),
        nrow = 2L
      )

    list_prepared_fold <-
      base::list(
        data_train_input = base::list(value = 1),
        data_test_input = base::list(value = 2),
        data_test_observed = data_observed
      )

    list_fold_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 2L,
        n_train_locations = 3L,
        n_test_locations = 2L,
        n_train_samples = 4L,
        n_test_samples = 2L,
        cv_strategy = "spatially_stratified_group_kfold"
      )

    fit_function <- function(data_train_input, candidate, seed) {
      return(base::list(candidate = candidate, seed = seed))
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
      run_sjsdm_prepared_tuning_candidate(
        data_candidate = data_candidate,
        list_prepared_fold = list_prepared_fold,
        list_fold_context = list_fold_context,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        seed = 900723L
      )

    testthat::expect_named(
      list_result,
      base::c("data_tuning", "list_prediction")
    )
    testthat::expect_identical(
      list_result[["data_tuning"]][["fit_status"]],
      "ok"
    )
    testthat::expect_identical(
      list_result[["data_tuning"]][["fit_seed"]],
      list_result[["list_prediction"]][["fit_seed"]]
    )
    testthat::expect_equal(
      list_result[["data_tuning"]][[
        "negative_log_likelihood_per_response"
      ]],
      0.25
    )
    testthat::expect_true(
      base::is.matrix(
        list_result[["list_prediction"]][["data_predicted"]]
      )
    )
  }
)

testthat::test_that(
  "run_sjsdm_prepared_tuning_candidate() preserves failure stages",
  {
    data_candidate <-
      tibble::tibble(
        candidate_id = "candidate_1",
        alpha_cov = 0,
        alpha_coef = 0,
        alpha_spatial = 0,
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1
      )

    data_observed <-
      base::matrix(base::c(0, 1), nrow = 1L)

    list_prepared_fold <-
      base::list(
        data_train_input = base::list(),
        data_test_input = base::list(),
        data_test_observed = data_observed
      )

    list_fold_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 1L,
        n_train_locations = 1L,
        n_test_locations = 1L,
        n_train_samples = 1L,
        n_test_samples = 1L,
        cv_strategy = "leave_one_location_out"
      )

    fit_error_function <- function(...) {
      base::stop("fit failed")
    }

    predict_function <- function(...) {
      return(data_observed)
    }

    list_fit_error <-
      run_sjsdm_prepared_tuning_candidate(
        data_candidate = data_candidate,
        list_prepared_fold = list_prepared_fold,
        list_fold_context = list_fold_context,
        fit_function = fit_error_function,
        predict_function = predict_function
      )

    testthat::expect_identical(
      list_fit_error[["data_tuning"]][["fit_status"]],
      "fit_error"
    )
    testthat::expect_match(
      list_fit_error[["data_tuning"]][["error_message"]],
      "fit failed"
    )
    testthat::expect_null(
      list_fit_error[["list_prediction"]][["data_predicted"]]
    )
  }
)

testthat::test_that(
  "run_sjsdm_prepared_tuning_candidate() is seed deterministic",
  {
    data_candidate <-
      tibble::tibble(
        candidate_id = "candidate_1",
        alpha_cov = 0,
        alpha_coef = 0,
        alpha_spatial = 0,
        lambda_cov = 0,
        lambda_coef = 0,
        lambda_spatial = 0
      )

    list_prepared_fold <-
      base::list(
        data_train_input = base::list(),
        data_test_input = base::list(),
        data_test_observed = base::matrix(0, nrow = 1L)
      )

    list_fold_context <-
      base::list(
        repeat_id = 2L,
        fold_id = 3L,
        n_train_locations = 1L,
        n_test_locations = 1L,
        n_train_samples = 1L,
        n_test_samples = 1L,
        cv_strategy = "leave_one_location_out"
      )

    fit_function <- function(data_train_input, candidate, seed) {
      return(seed)
    }

    predict_function <- function(object, data_test_input) {
      return(base::matrix(0.5, nrow = 1L))
    }

    score_function <- function(...) {
      return(
        base::list(
          n_taxa_retained = 1L,
          n_response_values = 1L,
          negative_log_likelihood_test = 1,
          negative_log_likelihood_per_response = 1,
          auc_macro_test = NA_real_
        )
      )
    }

    list_first <-
      run_sjsdm_prepared_tuning_candidate(
        data_candidate = data_candidate,
        list_prepared_fold = list_prepared_fold,
        list_fold_context = list_fold_context,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        seed = 900723L
      )

    list_second <-
      run_sjsdm_prepared_tuning_candidate(
        data_candidate = data_candidate,
        list_prepared_fold = list_prepared_fold,
        list_fold_context = list_fold_context,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        seed = 900723L
      )

    testthat::expect_identical(
      list_first[["data_tuning"]][["fit_seed"]],
      list_second[["data_tuning"]][["fit_seed"]]
    )
    testthat::expect_identical(
      list_first[["data_tuning"]][["score_seed"]],
      list_second[["data_tuning"]][["score_seed"]]
    )
  }
)

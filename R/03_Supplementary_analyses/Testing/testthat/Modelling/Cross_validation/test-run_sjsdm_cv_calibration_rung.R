testthat::test_that(
  "run_sjsdm_cv_calibration_rung() scores cached folds at one budget",
  {
    data_candidates <-
      tibble::tibble(
        candidate_id = base::c("candidate_1", "candidate_2"),
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = base::c(0, 0.1),
        lambda_coef = 0,
        lambda_spatial = 0
      )
    list_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 1L,
        n_train_locations = 2L,
        n_test_locations = 1L,
        n_train_samples = 4L,
        n_test_samples = 2L,
        cv_strategy = "grouped_kfold"
      )
    list_prepared_folds <-
      base::list(
        repeat_001__fold_001 = base::list(
          list_fold_context = list_context,
          list_prepared_fold = base::list(
            data_train_input = base::list(value = TRUE),
            data_test_input = base::list(value = TRUE),
            data_test_observed = base::matrix(
              base::c(0, 1, 1, 0),
              nrow = 2L
            )
          ),
          preparation_status = "ok"
        )
      )
    candidate_fit_function <- function(
        data_train_input,
        candidate,
        sel_abiotic_formula,
        config_sjsdm_cv_fitting,
        seed,
        repeat_id,
        fold_id,
        device) {
      base::structure(
        base::list(
          mod_fit = base::list(
            candidate_id = candidate[["candidate_id"]][[1L]]
          ),
          data_attempts = tibble::tibble(
            candidate_id = candidate[["candidate_id"]][[1L]],
            repeat_id = repeat_id,
            fold_id = fold_id,
            attempt = 1L,
            n_iter_budget = config_sjsdm_cv_fitting[["n_iter_max"]],
            n_sampling = config_sjsdm_cv_fitting[["n_sampling"]],
            epochs_run = config_sjsdm_cv_fitting[["n_iter_max"]],
            linear_trend_slope = 0,
            median_diff = 0,
            converged = TRUE,
            early_stopping_triggered = FALSE,
            runtime_seconds = 1,
            fit_seed = seed,
            fit_status = "ok",
            error_message = NA_character_
          ),
          fit_status = "ok",
          error_message = NA_character_,
          converged = TRUE,
          actual_n_iter = config_sjsdm_cv_fitting[["n_iter_max"]],
          actual_n_sampling = config_sjsdm_cv_fitting[["n_sampling"]],
          epochs_run = config_sjsdm_cv_fitting[["n_iter_max"]],
          linear_trend_slope = 0,
          median_diff = 0,
          early_stopping_triggered = FALSE
        ),
        class = base::c("sjsdm_cv_fit_result", "list")
      )
    }
    score_function <- function(...) {
      base::list(
        n_taxa_retained = 2L,
        n_response_values = 4L,
        negative_log_likelihood_test = 1,
        negative_log_likelihood_per_response = 0.25,
        auc_macro_test = 0.75
      )
    }

    res <-
      run_sjsdm_cv_calibration_rung(
        data_candidates = data_candidates,
        list_prepared_folds = list_prepared_folds,
        data_budget = tibble::tibble(
          budget_order = 2L,
          n_iter = 1000L,
          n_sampling = 200L
        ),
        sel_abiotic_formula = ~ x,
        config_sjsdm_cv_fitting = base::list(
          n_iter_initial = 500L,
          n_iter_max = 2000L,
          n_sampling = 200L
        ),
        candidate_fit_function = candidate_fit_function,
        predict_function = function(...) base::matrix(0.5, 2L, 2L),
        score_function = score_function
      )

    testthat::expect_equal(base::nrow(res[["data_benchmark"]]), 2L)
    testthat::expect_true(base::all(res[["data_benchmark"]][["converged"]]))
    testthat::expect_equal(
      res[["data_benchmark"]][["normalized_loss"]],
      base::rep(0.25, 2L)
    )
    testthat::expect_equal(base::nrow(res[["data_fit_attempts"]]), 2L)
    testthat::expect_equal(
      res[["data_fit_attempts"]][["budget_order"]],
      base::rep(2L, 2L)
    )
  }
)

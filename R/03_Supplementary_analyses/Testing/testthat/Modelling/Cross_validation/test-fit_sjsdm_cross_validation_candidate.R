testthat::test_that(
  "fit_sjsdm_cross_validation_candidate escalates deterministically",
  {
    list_iterations <-
      base::list()
    list_seeds <-
      base::list()
    fit_function <- function(
        data_train_input,
        candidate,
        sel_abiotic_formula,
        config_model_fitting,
        seed,
        device,
        biotic = NULL) {
      list_iterations[[base::length(list_iterations) + 1L]] <<-
        config_model_fitting[["n_iter"]]
      list_seeds[[base::length(list_seeds) + 1L]] <<-
        seed
      structure(
        base::list(iter = config_model_fitting[["n_iter"]]),
        class = "test_fit"
      )
    }
    convergence_function <- function(mod_jsdm) {
      base::list(
        linear_trend_slope = if (mod_jsdm[["iter"]] < 2000L) 0.02 else 0,
        median_diff = if (mod_jsdm[["iter"]] < 2000L) 2 else 0,
        epochs_run = mod_jsdm[["iter"]],
        early_stopping_triggered = FALSE
      )
    }

    res <-
      fit_sjsdm_cross_validation_candidate(
        data_train_input = base::list(),
        candidate = tibble::tibble(
          candidate_id = 1L,
          alpha_cov = 0.5,
          alpha_coef = 0.5,
          alpha_spatial = 0.5,
          lambda_cov = 0,
          lambda_coef = 0,
          lambda_spatial = 0
        ),
        sel_abiotic_formula = stats::as.formula("~ 1"),
        config_sjsdm_cv_fitting = base::list(
          n_iter = 500L,
          n_iter_initial = 500L,
          n_iter_max = 4000L,
          n_sampling = 200L,
          n_step_size = NULL,
          n_early_stopping = NULL
        ),
        seed = 42L,
        repeat_id = 1L,
        fold_id = 2L,
        fit_function = fit_function,
        convergence_function = convergence_function
      )

    testthat::expect_equal(unlist(list_iterations), c(500L, 1000L, 2000L))
    testthat::expect_equal(unlist(list_seeds), c(42L, 42L, 42L))
    testthat::expect_equal(res[["fit_status"]], "ok")
    testthat::expect_equal(res[["actual_n_iter"]], 2000L)
    testthat::expect_true(res[["converged"]])
    testthat::expect_equal(res[["data_attempts"]][["attempt"]], 1:3)
    testthat::expect_equal(
      unique(res[["data_attempts"]][["repeat_id"]]),
      1L
    )
    testthat::expect_equal(
      unique(res[["data_attempts"]][["fold_id"]]),
      2L
    )
  }
)

testthat::test_that(
  "fit_sjsdm_cross_validation_candidate caps and marks non-convergence",
  {
    fit_function <- function(
        data_train_input,
        candidate,
        sel_abiotic_formula,
        config_model_fitting,
        seed,
        device,
        biotic = NULL) {
      base::list(iter = config_model_fitting[["n_iter"]])
    }
    convergence_function <- function(mod_jsdm) {
      base::list(
        linear_trend_slope = 0.02,
        median_diff = 1,
        epochs_run = mod_jsdm[["iter"]],
        early_stopping_triggered = FALSE
      )
    }

    res <-
      fit_sjsdm_cross_validation_candidate(
        data_train_input = base::list(),
        candidate = tibble::tibble(
          candidate_id = 1L,
          alpha_cov = 0.5,
          alpha_coef = 0.5,
          alpha_spatial = 0.5,
          lambda_cov = 0,
          lambda_coef = 0,
          lambda_spatial = 0
        ),
        sel_abiotic_formula = stats::as.formula("~ 1"),
        config_sjsdm_cv_fitting = base::list(
          n_iter = 750L,
          n_iter_initial = 750L,
          n_iter_max = 2000L,
          n_sampling = 200L,
          n_step_size = NULL,
          n_early_stopping = NULL
        ),
        seed = 42L,
        repeat_id = 1L,
        fold_id = 1L,
        fit_function = fit_function,
        convergence_function = convergence_function
      )

    testthat::expect_equal(
      res[["data_attempts"]][["n_iter_budget"]],
      c(750L, 1500L, 2000L)
    )
    testthat::expect_equal(res[["fit_status"]], "non_converged")
    testthat::expect_false(res[["converged"]])
    testthat::expect_equal(res[["actual_n_iter"]], 2000L)
  }
)

testthat::test_that(
  "fit_sjsdm_cross_validation_candidate does not escalate fit errors",
  {
    n_calls <- 0L
    fit_function <- function(...) {
      n_calls <<- n_calls + 1L
      base::stop("ordinary fit failure")
    }

    res <-
      fit_sjsdm_cross_validation_candidate(
        data_train_input = base::list(),
        candidate = tibble::tibble(
          candidate_id = 1L,
          alpha_cov = 0.5,
          alpha_coef = 0.5,
          alpha_spatial = 0.5,
          lambda_cov = 0,
          lambda_coef = 0,
          lambda_spatial = 0
        ),
        sel_abiotic_formula = stats::as.formula("~ 1"),
        config_sjsdm_cv_fitting = base::list(
          n_iter = 500L,
          n_iter_initial = 500L,
          n_iter_max = 4000L,
          n_sampling = 200L,
          n_step_size = NULL,
          n_early_stopping = NULL
        ),
        seed = 42L,
        repeat_id = 1L,
        fold_id = 1L,
        fit_function = fit_function,
        convergence_function = function(mod_jsdm) base::list()
      )

    testthat::expect_equal(n_calls, 1L)
    testthat::expect_equal(res[["fit_status"]], "fit_error")
    testthat::expect_match(res[["error_message"]], "ordinary fit failure")
    testthat::expect_equal(base::nrow(res[["data_attempts"]]), 1L)
  }
)

testthat::test_that(
  "build_sjsdm_candidate_fold_result() preserves result contracts",
  {
    data_candidate <-
      build_sjsdm_regularization_candidates(lambda_cov = 0)

    list_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 2L,
        n_train_locations = 3L,
        n_test_locations = 1L,
        n_train_samples = 6L,
        n_test_samples = 2L,
        cv_strategy = "leave_one_location_out"
      )

    data_metrics <-
      base::list(
        n_taxa_retained = 2L,
        n_response_values = 4L,
        negative_log_likelihood_test = 1.2,
        negative_log_likelihood_per_response = 0.3,
        auc_macro_test = 0.8
      )

    data_predicted <-
      base::matrix(0.5, nrow = 2L, ncol = 2L)

    res <-
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_context,
        fit_seed = 11L,
        score_seed = 12L,
        fit_status = "ok",
        data_metrics = data_metrics,
        data_predicted = data_predicted,
        fit_seconds = 1,
        prediction_seconds = 2,
        scoring_seconds = 3
      )

    testthat::expect_named(
      res,
      base::c("data_tuning", "list_prediction")
    )
    testthat::expect_equal(base::nrow(res[["data_tuning"]]), 1L)
    testthat::expect_identical(
      res[["data_tuning"]][["fit_status"]],
      "ok"
    )
    testthat::expect_identical(
      res[["data_tuning"]][["fit_seed"]],
      11L
    )
    testthat::expect_identical(
      res[["data_tuning"]][["n_taxa_retained"]],
      2L
    )
    testthat::expect_identical(
      res[["list_prediction"]][["data_predicted"]],
      data_predicted
    )
    testthat::expect_false(
      base::any(
        purrr::map_lgl(res, ~ base::inherits(.x, "sjSDM"))
      )
    )
  }
)

testthat::test_that(
  "build_sjsdm_candidate_fold_result() validates status and metrics",
  {
    data_candidate <-
      build_sjsdm_regularization_candidates(lambda_cov = 0)

    list_context <-
      base::list(
        repeat_id = 1L,
        fold_id = 1L,
        n_train_locations = 1L,
        n_test_locations = 1L,
        n_train_samples = 1L,
        n_test_samples = 1L,
        cv_strategy = "leave_one_location_out"
      )

    testthat::expect_error(
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_context,
        fit_status = "unknown"
      ),
      "fit_status"
    )

    testthat::expect_error(
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_context,
        fit_status = "ok",
        data_metrics = base::list()
      ),
      "metrics"
    )
  }
)

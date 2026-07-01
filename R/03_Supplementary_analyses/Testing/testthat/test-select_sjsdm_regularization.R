testthat::test_that(
  "select_sjsdm_regularization() minimizes normalized held-out loss",
  {
    data_summary <-
      tidyr::crossing(
        repeat_id = 1:2,
        candidate_id = base::c("candidate_001", "candidate_002")
      ) |>
      dplyr::mutate(
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          0.1,
          0.2
        ),
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        n_folds_total = 2L,
        n_folds_successful = 2L,
        n_response_values = 40L,
        negative_log_likelihood_test = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          20,
          12
        ),
        negative_log_likelihood_per_response = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          0.5,
          0.3
        ),
        auc_macro_test = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          0.9,
          0.6
        ),
        summary_status = "ok",
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv"
      )

    res <-
      select_sjsdm_regularization(data_tuning_summary = data_summary)

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(res[["candidate_id"]], "candidate_002")
    testthat::expect_equal(res[["selection_metric_value"]], 0.3)
    testthat::expect_equal(
      res[["selection_metric"]],
      "negative_log_likelihood_per_response"
    )
    testthat::expect_equal(res[["n_repeats"]], 2L)
    testthat::expect_equal(res[["candidate_rank"]], 1L)
    testthat::expect_equal(res[["regularization_source"]], "unit_cv")
  }
)

testthat::test_that(
  "select_sjsdm_regularization() resolves ties by candidate identifier",
  {
    data_summary <-
      tibble::tibble(
        repeat_id = base::rep(1:2, 2L),
        candidate_id = base::rep(
          base::c("candidate_002", "candidate_001"),
          each = 2L
        ),
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = base::rep(base::c(0.2, 0.1), each = 2L),
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        n_folds_total = 2L,
        n_folds_successful = 2L,
        n_response_values = 40L,
        negative_log_likelihood_test = 16,
        negative_log_likelihood_per_response = 0.4,
        auc_macro_test = 0.7,
        summary_status = "ok",
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv"
      )

    res <-
      select_sjsdm_regularization(data_tuning_summary = data_summary)

    testthat::expect_equal(res[["candidate_id"]], "candidate_001")
  }
)

testthat::test_that(
  "select_sjsdm_regularization() excludes incomplete candidates",
  {
    data_summary <-
      tibble::tibble(
        repeat_id = base::rep(1:2, 2L),
        candidate_id = base::rep(
          base::c("candidate_001", "candidate_002"),
          each = 2L
        ),
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = base::rep(base::c(0.1, 0.2), each = 2L),
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        n_folds_total = 2L,
        n_folds_successful = base::c(2L, 1L, 2L, 2L),
        n_response_values = base::c(40L, NA_integer_, 40L, 40L),
        negative_log_likelihood_test = base::c(4, NA_real_, 20, 20),
        negative_log_likelihood_per_response =
          base::c(0.1, NA_real_, 0.5, 0.5),
        auc_macro_test = base::c(0.9, NA_real_, 0.7, 0.7),
        summary_status = base::c("ok", "incomplete", "ok", "ok"),
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv"
      )

    res <-
      select_sjsdm_regularization(data_tuning_summary = data_summary)

    testthat::expect_equal(res[["candidate_id"]], "candidate_002")

    testthat::expect_error(
      select_sjsdm_regularization(
        data_tuning_summary = dplyr::filter(
          data_summary,
          .data[["candidate_id"]] == "candidate_001"
        )
      ),
      "No candidate completed every repeat"
    )
  }
)

testthat::test_that(
  "select_sjsdm_regularization() weights repeats equally",
  {
    data_summary <-
      tibble::tibble(
        repeat_id = base::rep(1:2, 2L),
        candidate_id = base::rep(
          base::c("candidate_001", "candidate_002"),
          each = 2L
        ),
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = base::rep(base::c(0.1, 0.2), each = 2L),
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        n_folds_total = 2L,
        n_folds_successful = 2L,
        n_response_values = base::c(10L, 1000L, 10L, 1000L),
        negative_log_likelihood_test = base::c(1, 900, 2, 400),
        negative_log_likelihood_per_response =
          base::c(0.1, 0.9, 0.2, 0.4),
        auc_macro_test = 0.7,
        summary_status = "ok",
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv"
      )

    res <-
      select_sjsdm_regularization(data_tuning_summary = data_summary)

    testthat::expect_equal(res[["candidate_id"]], "candidate_002")
    testthat::expect_equal(res[["selection_metric_value"]], 0.3)
  }
)

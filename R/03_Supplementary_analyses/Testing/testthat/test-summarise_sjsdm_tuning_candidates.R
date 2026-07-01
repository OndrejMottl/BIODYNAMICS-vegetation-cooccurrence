testthat::test_that(
  "summarise_sjsdm_tuning_candidates() pools folds within repeats",
  {
    data_tuning <-
      tidyr::crossing(
        repeat_id = 1:2,
        fold_id = 1:2,
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
        n_response_values = dplyr::if_else(
          .data[["fold_id"]] == 1L,
          10L,
          30L
        ),
        negative_log_likelihood_test = dplyr::case_when(
          .data[["repeat_id"]] == 1L & .data[["fold_id"]] == 1L ~ 2,
          .data[["repeat_id"]] == 1L ~ 9,
          .data[["fold_id"]] == 1L ~ 4,
          .default = 12
        ),
        negative_log_likelihood_per_response =
          .data[["negative_log_likelihood_test"]] /
          .data[["n_response_values"]],
        auc_macro_test = 0.75,
        fit_status = "ok",
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv"
      )

    res <-
      summarise_sjsdm_tuning_candidates(data_tuning = data_tuning)

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "candidate_id",
        "alpha_cov",
        "alpha_coef",
        "alpha_spatial",
        "lambda_cov",
        "lambda_coef",
        "lambda_spatial",
        "n_folds_total",
        "n_folds_successful",
        "n_response_values",
        "negative_log_likelihood_test",
        "negative_log_likelihood_per_response",
        "auc_macro_test",
        "summary_status",
        "cv_strategy",
        "regularization_source"
      )
    )
    testthat::expect_equal(
      res[["negative_log_likelihood_per_response"]],
      base::c(0.25, 0.25, 0.4, 0.4)
    )
    testthat::expect_equal(res[["n_response_values"]], base::rep(40L, 4L))
    testthat::expect_true(base::all(res[["summary_status"]] == "ok"))
  }
)

testthat::test_that(
  "summarise_sjsdm_tuning_candidates() retains incomplete candidates",
  {
    data_tuning <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        fold_id = base::c(1L, 2L),
        candidate_id = "candidate_001",
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        n_response_values = base::c(20L, NA_integer_),
        negative_log_likelihood_test = base::c(4, NA_real_),
        negative_log_likelihood_per_response = base::c(0.2, NA_real_),
        auc_macro_test = base::c(0.8, NA_real_),
        fit_status = base::c("ok", "fit_error"),
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv"
      )

    res <-
      summarise_sjsdm_tuning_candidates(data_tuning = data_tuning)

    testthat::expect_equal(res[["n_folds_total"]], 2L)
    testthat::expect_equal(res[["n_folds_successful"]], 1L)
    testthat::expect_equal(res[["summary_status"]], "incomplete")
    testthat::expect_true(
      base::all(
        base::is.na(
          res[
            base::c(
              "n_response_values",
              "negative_log_likelihood_test",
              "negative_log_likelihood_per_response",
              "auc_macro_test"
            )
          ]
        )
      )
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_tuning_candidates() validates the runner schema",
  {
    testthat::expect_error(
      summarise_sjsdm_tuning_candidates(data_tuning = tibble::tibble()),
      "non-empty"
    )

    testthat::expect_error(
      summarise_sjsdm_tuning_candidates(
        data_tuning = tibble::tibble(repeat_id = 1L)
      ),
      "missing required columns"
    )
  }
)

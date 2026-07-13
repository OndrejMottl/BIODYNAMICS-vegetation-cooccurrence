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

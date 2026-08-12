testthat::test_that(
  "run_sjsdm_selected_fold() preserves preparation failures",
  {
    callback_called <- FALSE

    callback <- function(...) {
      callback_called <<- TRUE
      base::stop("Candidate callback must not run.")
    }

    res <-
      run_sjsdm_selected_fold(
        list_fold_context = base::list(
          repeat_id = 1L,
          fold_id = 2L,
          train_indices = 1L,
          test_indices = 2L,
          n_train_samples = 1L,
          n_test_samples = 1L,
          cv_strategy = "leave_one_location_out"
        ),
        data_candidate =
          build_sjsdm_regularization_candidates(lambda_cov = 0),
        data_sample_ids = tibble::tibble(
          sample_id = base::c("a__0", "b__0"),
          row_index = 1:2,
          location_id = base::c("a", "b"),
          dataset_name = base::c("a", "b"),
          age = 0
        ),
        taxon_names = "taxon_a",
        regularization_source = "unit_cv",
        prepare_fold_function = function(...) {
          base::stop("fold preparation failed")
        },
        fit_function = callback,
        predict_function = callback,
        seed = 100L
      )

    testthat::expect_false(callback_called)
    testthat::expect_identical(
      res[["data_diagnostics"]][["fit_status"]],
      "preparation_error"
    )
    testthat::expect_match(
      res[["data_diagnostics"]][["error_message"]],
      "fold preparation failed"
    )
    testthat::expect_equal(base::nrow(res[["data_predictions"]]), 1L)
  }
)

testthat::test_that(
  "build_sjsdm_empty_selected_fold_artifacts() preserves schemas",
  {
    res <-
      build_sjsdm_empty_selected_fold_artifacts()

    testthat::expect_named(
      res,
      base::c("data_predictions", "data_diagnostics")
    )
    testthat::expect_equal(base::nrow(res[["data_predictions"]]), 0L)
    testthat::expect_equal(base::nrow(res[["data_diagnostics"]]), 0L)
    testthat::expect_named(
      res[["data_predictions"]],
      base::c(
        "repeat_id",
        "fold_id",
        "row_index",
        "location_id",
        "dataset_name",
        "age",
        "taxon",
        "observed",
        "predicted_probability",
        "null_probability",
        "prediction_status"
      )
    )
    testthat::expect_named(
      res[["data_diagnostics"]],
      base::c(
        "repeat_id",
        "fold_id",
        "candidate_id",
        "fit_seed",
        "n_train_samples",
        "n_test_samples",
        "n_taxa_retained",
        "n_effective_mev",
        "fit_status",
        "error_message",
        "cv_strategy",
        "regularization_source"
      )
    )
  }
)

testthat::test_that(
  ".build_empty_spatial_model_results() preserves the result schema",
  {
    data_result <-
      .build_empty_spatial_model_results()

    testthat::expect_s3_class(data_result, "tbl_df")
    testthat::expect_equal(base::nrow(data_result), 0L)
    testthat::expect_named(
      data_result,
      base::c(
        "data_source",
        "scale",
        "scale_id",
        "pipeline_name",
        "store_path",
        "resolution_id",
        "component",
        "R2_Nagelkerke_adjusted",
        "R2_Nagelkerke_percentage",
        "fitted_auc_mean",
        "fitted_auc_median",
        "fitted_auc_n",
        "predictive_tjur_r2_mean",
        "predictive_auc_mean",
        "predictive_log_loss_mean",
        "cv_strategy",
        "effective_folds",
        "cv_feasibility_status",
        "n_locations",
        "n_samples",
        "n_taxa",
        "n_effective_mev",
        "regularization_source",
        "source_tier",
        "candidate_id"
      )
    )
  }
)

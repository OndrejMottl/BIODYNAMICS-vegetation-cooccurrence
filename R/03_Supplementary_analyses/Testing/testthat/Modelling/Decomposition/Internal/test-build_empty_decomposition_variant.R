testthat::test_that(
  ".build_empty_decomposition_variant() preserves result schema",
  {
    res <-
      .build_empty_decomposition_variant(
        route_id = "route_a",
        repeat_id = 1L,
        fold_id = "fold_001",
        variant = "full",
        status = "error",
        error_message = "fit failed"
      )

    testthat::expect_named(
      res,
      base::c(
        "route_id",
        "repeat_id",
        "fold_id",
        "variant",
        "status",
        "error_message",
        "warning_text",
        "converged",
        "linear_trend_slope",
        "median_diff",
        "epochs_run",
        "early_stopping_triggered",
        "loss",
        "brier",
        "auc",
        "auc_macro",
        "n_train_samples",
        "n_test_samples",
        "n_taxa_raw",
        "n_taxa_retained",
        "n_taxa_dropped"
      )
    )
    testthat::expect_identical(res[["status"]], "error")
    testthat::expect_false(res[["converged"]])
  }
)

testthat::test_that(
  "prepare_sjsdm_guardrail_repeat_metrics() pivots complete metrics",
  {
    data_metrics <-
      tidyr::crossing(
        repeat_id = 1:2,
        metric_id = base::c(
          "auc",
          "brier_score",
          "log_loss",
          "tjur_r2"
        )
      ) |>
      dplyr::mutate(
        prediction_source = "model",
        aggregation_id = "fold_macro",
        estimate = 0.5
      )

    res <-
      prepare_sjsdm_guardrail_repeat_metrics(
        data_metrics = data_metrics,
        suffix = "_candidate"
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true("auc_candidate" %in% base::names(res))
    testthat::expect_true("tjur_r2_candidate" %in% base::names(res))
  }
)

testthat::test_that(
  "compute_predictive_fold_shares() preserves loss output schema",
  {
    data_fold <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 2L,
        variant = base::c(
          "full",
          "no_abiotic",
          "no_spatial",
          "no_associations"
        ),
        loss = base::c(10, 12, 11, 13),
        status = "ok"
      )

    res <-
      compute_predictive_fold_shares(
        data_fold = data_fold,
        value_column = "loss",
        direction = "lower"
      )

    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "fold_id",
        "component",
        "loss_full",
        "loss_reduced",
        "delta_loss",
        "delta_loss_clamped",
        "share",
        "defined"
      )
    )
    testthat::expect_equal(
      dplyr::pull(res, share),
      base::c(2, 1, 3) / 6 * 100
    )
  }
)

testthat::test_that(
  "compute_predictive_fold_shares() preserves metric output schema",
  {
    data_fold <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 2L,
        variant = base::c(
          "full",
          "no_abiotic",
          "no_spatial",
          "no_associations"
        ),
        auc_test = base::c(0.8, 0.7, 0.6, 0.75),
        status = "ok"
      )

    res <-
      compute_predictive_fold_shares(
        data_fold = data_fold,
        value_column = "auc_test",
        direction = "higher",
        metric_name = "AUC"
      )

    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "fold_id",
        "metric_name",
        "component",
        "metric_full",
        "metric_reduced",
        "delta_metric",
        "delta_metric_clamped",
        "share",
        "defined"
      )
    )
    testthat::expect_equal(base::unique(res[["metric_name"]]), "AUC")
  }
)

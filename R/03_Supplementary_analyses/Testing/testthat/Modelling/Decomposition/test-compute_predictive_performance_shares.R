testthat::test_that(
  "compute_predictive_performance_shares() computes shares",
  {
    data_metrics <-
      tibble::tibble(
        repeat_id = c(1L, 1L, 1L, 1L),
        fold_id = c(1L, 1L, 1L, 1L),
        variant = c(
          "full",
          "no_abiotic",
          "no_spatial",
          "no_associations"
        ),
        auc_test = c(0.8, 0.7, 0.6, 0.75),
        status = "ok"
      )

    res <-
      compute_predictive_performance_shares(
        data_fold_metrics = data_metrics,
        metric_column = "auc_test",
        metric_name = "AUC"
      )

    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_equal(
      dplyr::pull(res, share),
      c(0.1, 0.2, 0.05) / 0.35 * 100,
      tolerance = 1e-8
    )
    testthat::expect_true(base::all(dplyr::pull(res, defined)))
    testthat::expect_equal(base::unique(dplyr::pull(res, metric_name)), "AUC")
  }
)

testthat::test_that(
  "compute_predictive_performance_shares() clamps improvements",
  {
    data_metrics <-
      tibble::tibble(
        repeat_id = c(1L, 1L, 1L, 1L),
        fold_id = c(1L, 1L, 1L, 1L),
        variant = c(
          "full",
          "no_abiotic",
          "no_spatial",
          "no_associations"
        ),
        auc_test = c(0.8, 0.9, 0.7, 0.8),
        status = "ok"
      )

    res <-
      compute_predictive_performance_shares(
        data_fold_metrics = data_metrics,
        metric_column = "auc_test"
      )

    testthat::expect_equal(
      dplyr::pull(res, delta_metric_clamped),
      c(0, 0.1, 0),
      tolerance = 1e-8
    )
    testthat::expect_equal(
      dplyr::pull(res, share),
      c(0, 100, 0),
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "compute_predictive_performance_shares() flags undefined folds",
  {
    data_metrics <-
      tibble::tibble(
        repeat_id = c(1L, 1L, 1L, 1L),
        fold_id = c(1L, 1L, 1L, 1L),
        variant = c(
          "full",
          "no_abiotic",
          "no_spatial",
          "no_associations"
        ),
        auc_test = c(0.8, 0.9, 0.82, 0.81),
        status = "ok"
      )

    res <-
      compute_predictive_performance_shares(
        data_fold_metrics = data_metrics,
        metric_column = "auc_test"
      )

    testthat::expect_false(base::any(dplyr::pull(res, defined)))
    testthat::expect_true(base::all(base::is.na(dplyr::pull(res, share))))
  }
)

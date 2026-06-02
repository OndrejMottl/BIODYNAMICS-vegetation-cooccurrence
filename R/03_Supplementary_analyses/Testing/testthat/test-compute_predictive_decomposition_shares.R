testthat::test_that(
  "compute_predictive_decomposition_shares() computes shares",
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
        loss = c(10, 12, 11, 13),
        status = "ok"
      )

    res <-
      compute_predictive_decomposition_shares(
        data_fold_metrics = data_metrics
      )

    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_equal(
      dplyr::pull(res, share),
      c(2, 1, 3) / 6 * 100,
      tolerance = 1e-8
    )
    testthat::expect_true(base::all(dplyr::pull(res, defined)))
  }
)

testthat::test_that(
  "compute_predictive_decomposition_shares() clamps negatives",
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
        loss = c(10, 8, 11, 10),
        status = "ok"
      )

    res <-
      compute_predictive_decomposition_shares(
        data_fold_metrics = data_metrics
      )

    testthat::expect_equal(
      dplyr::pull(res, delta_loss_clamped),
      c(0, 1, 0),
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
  "compute_predictive_decomposition_shares() flags undefined folds",
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
        loss = c(10, 9, 10, 8),
        status = "ok"
      )

    res <-
      compute_predictive_decomposition_shares(
        data_fold_metrics = data_metrics
      )

    testthat::expect_false(base::any(dplyr::pull(res, defined)))
    testthat::expect_true(base::all(base::is.na(dplyr::pull(res, share))))
  }
)

testthat::test_that(
  "compute_predictive_decomposition_shares() handles failed variants",
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
        loss = c(10, 12, NA_real_, 13),
        status = c("ok", "ok", "error", "ok")
      )

    res <-
      compute_predictive_decomposition_shares(
        data_fold_metrics = data_metrics
      )

    testthat::expect_false(base::any(dplyr::pull(res, defined)))
    testthat::expect_true(base::all(base::is.na(dplyr::pull(res, share))))
  }
)

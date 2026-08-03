testthat::test_that(
  "compute_decomposition_prediction_metrics() returns metrics",
  {
    data_observed <-
      base::matrix(
        data = c(1, 0, 0, 1),
        nrow = 2,
        dimnames = base::list(
          c("a", "b"),
          c("taxon_a", "taxon_b")
        )
      )

    data_predicted <-
      base::matrix(
        data = c(0.9, 0.2, 0.1, 0.8),
        nrow = 2,
        dimnames = base::list(
          c("a", "b"),
          c("taxon_a", "taxon_b")
        )
      )

    res <-
      compute_decomposition_prediction_metrics(
        data_observed = data_observed,
        data_predicted = data_predicted
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_true(base::is.finite(res[["loss"]]))
    testthat::expect_true(base::is.finite(res[["brier"]]))
    testthat::expect_equal(res[["auc"]], 1)
  }
)

testthat::test_that(
  "compute_decomposition_prediction_metrics() validates dimensions",
  {
    data_observed <-
      base::matrix(data = c(1, 0), nrow = 1)

    data_predicted <-
      base::matrix(data = c(0.5, 0.5, 0.5), nrow = 1)

    testthat::expect_error(
      compute_decomposition_prediction_metrics(
        data_observed = data_observed,
        data_predicted = data_predicted
      ),
      "dimensions must match"
    )
  }
)

testthat::test_that(
  "compute_decomposition_prediction_metrics() handles unnamed predictions",
  {
    data_observed <-
      base::matrix(
        data = c(1, 0, 0, 1),
        nrow = 2,
        dimnames = base::list(
          c("a", "b"),
          c("taxon_a", "taxon_b")
        )
      )

    data_predicted <-
      base::matrix(
        data = c(0.9, 0.2, 0.1, 0.8),
        nrow = 2
      )

    res <-
      compute_decomposition_prediction_metrics(
        data_observed = data_observed,
        data_predicted = data_predicted
      )

    testthat::expect_equal(res[["auc_macro"]], 1)
  }
)

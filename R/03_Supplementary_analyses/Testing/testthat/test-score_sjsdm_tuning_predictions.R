testthat::test_that(
  "score_sjsdm_tuning_predictions() returns compact metrics",
  {
    data_observed <-
      base::matrix(
        data = base::c(0, 1, 1, 0),
        nrow = 2L,
        dimnames = base::list(
          base::c("a", "b"),
          base::c("taxon_a", "taxon_b")
        )
      )

    data_predicted <-
      data_observed * 0.8 + 0.1

    res <-
      score_sjsdm_tuning_predictions(
        data_observed = data_observed,
        data_predicted = data_predicted
      )

    testthat::expect_equal(res[["n_taxa_retained"]], 2L)
    testthat::expect_equal(res[["n_response_values"]], 4L)
    testthat::expect_equal(
      res[["negative_log_likelihood_test"]],
      -4 * base::log(0.9)
    )
    testthat::expect_equal(
      res[["negative_log_likelihood_per_response"]],
      -base::log(0.9)
    )
    testthat::expect_equal(res[["auc_macro_test"]], 1)
  }
)

testthat::test_that(
  "score_sjsdm_tuning_predictions() rejects misaligned names",
  {
    data_observed <-
      base::matrix(
        data = base::c(0, 1, 1, 0),
        nrow = 2L,
        dimnames = base::list(
          base::c("a", "b"),
          base::c("taxon_a", "taxon_b")
        )
      )

    data_predicted <-
      data_observed

    base::rownames(data_predicted) <-
      base::rev(base::rownames(data_predicted))

    testthat::expect_error(
      score_sjsdm_tuning_predictions(
        data_observed = data_observed,
        data_predicted = data_predicted
      ),
      "aligned"
    )
  }
)

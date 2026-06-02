testthat::test_that(
  "summarize_predictive_decomposition() summarizes shares",
  {
    data_shares <-
      tibble::tibble(
        component = c(
          "Abiotic",
          "Abiotic",
          "Spatial",
          "Spatial"
        ),
        share = c(20, 40, 80, 60),
        defined = c(TRUE, TRUE, TRUE, TRUE)
      )

    res <-
      summarize_predictive_decomposition(data_shares = data_shares)

    vec_median <-
      res |>
      dplyr::arrange(.data$component) |>
      dplyr::pull(.data$share_median)

    testthat::expect_equal(vec_median, c(30, 70))
    testthat::expect_true(
      base::all(base::is.finite(dplyr::pull(res, lwr_95)))
    )
    testthat::expect_equal(dplyr::pull(res, n_defined), c(2L, 2L))
  }
)

testthat::test_that(
  "summarize_predictive_decomposition() handles undefined shares",
  {
    data_shares <-
      tibble::tibble(
        component = c("Abiotic", "Abiotic"),
        share = c(NA_real_, NA_real_),
        defined = c(FALSE, FALSE)
      )

    res <-
      summarize_predictive_decomposition(data_shares = data_shares)

    testthat::expect_true(base::is.na(res[["share_median"]][[1L]]))
    testthat::expect_equal(res[["n_defined"]][[1L]], 0L)
    testthat::expect_equal(res[["n_failed"]][[1L]], 2L)
    testthat::expect_equal(res[["proportion_defined"]][[1L]], 0)
  }
)

testthat::test_that(
  ".resolve_decomposition_fold_loss() requires one matching loss",
  {
    data_fold <-
      tibble::tibble(
        variant = base::c("full", "no_abiotic", "full"),
        loss = base::c(1, 2, 3)
      )

    testthat::expect_equal(
      .resolve_decomposition_fold_loss(data_fold, "no_abiotic"),
      2
    )
    testthat::expect_true(
      base::is.na(.resolve_decomposition_fold_loss(data_fold, "full"))
    )
  }
)

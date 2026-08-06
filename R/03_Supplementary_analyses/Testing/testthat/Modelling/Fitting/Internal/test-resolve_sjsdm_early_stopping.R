testthat::test_that(
  ".resolve_sjsdm_early_stopping() preserves three-tier semantics",
  {
    testthat::expect_identical(
      .resolve_sjsdm_early_stopping(
        iter = 100L,
        n_early_stopping = NULL
      ),
      20L
    )
    testthat::expect_identical(
      .resolve_sjsdm_early_stopping(
        iter = 100L,
        n_early_stopping = -1L
      ),
      0L
    )
    testthat::expect_identical(
      .resolve_sjsdm_early_stopping(
        iter = 100L,
        n_early_stopping = 10L
      ),
      20L
    )
    testthat::expect_identical(
      .resolve_sjsdm_early_stopping(
        iter = 100L,
        n_early_stopping = 30L
      ),
      30L
    )
  }
)

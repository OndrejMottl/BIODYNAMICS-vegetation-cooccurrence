testthat::test_that(
  "resolve_spatial_mev_strategy() selects exact below the shared boundary",
  {
    res <-
      resolve_spatial_mev_strategy(
        strategy = "auto",
        n_locations = 1999L,
        n_mev = 3L,
        exact_max_locations = 1999L,
        fast_eigenvectors = 200L
      )

    testthat::expect_identical(
      res[["strategy_selected"]],
      "exact"
    )
    testthat::expect_identical(
      res[["strategy_version"]],
      "spatial_mev_exact_v1"
    )
  }
)

testthat::test_that(
  "resolve_spatial_mev_strategy() selects fast above the shared boundary",
  {
    res <-
      resolve_spatial_mev_strategy(
        strategy = "auto",
        n_locations = 2000L,
        n_mev = 3L,
        exact_max_locations = 1999L,
        fast_eigenvectors = 200L
      )

    testthat::expect_identical(
      res[["strategy_selected"]],
      "fast"
    )
    testthat::expect_identical(
      res[["strategy_version"]],
      "spatial_mev_nystrom_v1"
    )
  }
)

testthat::test_that(
  "resolve_spatial_mev_strategy() rejects unsafe forced exact construction",
  {
    testthat::expect_error(
      resolve_spatial_mev_strategy(
        strategy = "exact",
        n_locations = 2000L,
        n_mev = 3L,
        exact_max_locations = 1999L,
        fast_eigenvectors = 200L
      ),
      regexp = "dense MEM safety limit"
    )
  }
)

testthat::test_that(
  "resolve_spatial_mev_strategy() rejects malformed configuration",
  {
    testthat::expect_error(
      resolve_spatial_mev_strategy(
        strategy = "continental",
        n_locations = 100L,
        n_mev = 3L,
        exact_max_locations = 1999L,
        fast_eigenvectors = 200L
      ),
      regexp = "exact.*fast.*auto"
    )

    testthat::expect_error(
      resolve_spatial_mev_strategy(
        strategy = "auto",
        n_locations = 100L,
        n_mev = 3L,
        exact_max_locations = 1999.5,
        fast_eigenvectors = 200L
      ),
      regexp = "exact_max_locations"
    )

    testthat::expect_error(
      resolve_spatial_mev_strategy(
        strategy = "auto",
        n_locations = 100L,
        n_mev = 201L,
        exact_max_locations = 1999L,
        fast_eigenvectors = 200L
      ),
      regexp = "fast_eigenvectors.*n_mev"
    )
  }
)

testthat::test_that(
  "compute_fast_spatial_mev_basis() is fixed-seed deterministic",
  {
    mat_coords <-
      base::matrix(
        base::seq_len(10L),
        ncol = 2L
      )

    fast_function <- function(
        coords,
        model,
        enum,
        threshold,
        interact) {
      return(
        base::list(
          sf = base::matrix(
            stats::runif(base::nrow(coords) * 2L),
            ncol = 2L
          ),
          other = base::list(fast = 1L)
        )
      )
    }

    base::set.seed(42L)
    random_before <-
      stats::runif(1L)

    res_first <-
      compute_fast_spatial_mev_basis(
        mat_coords = mat_coords,
        fast_eigenvectors = 2L,
        fast_seed = 900723L,
        fast_function = fast_function
      )

    random_after <-
      stats::runif(1L)

    base::set.seed(42L)
    testthat::expect_equal(random_before, stats::runif(1L))
    testthat::expect_equal(random_after, stats::runif(1L))

    res_second <-
      compute_fast_spatial_mev_basis(
        mat_coords = mat_coords,
        fast_eigenvectors = 2L,
        fast_seed = 900723L,
        fast_function = fast_function
      )

    testthat::expect_equal(
      res_first[["mat_mev_all"]],
      res_second[["mat_mev_all"]]
    )
    testthat::expect_identical(
      res_first[["list_fast_basis"]][["other"]][["fast"]],
      1L
    )
    testthat::expect_identical(
      res_first[["engine_method"]],
      "spmoran_nystrom"
    )
    testthat::expect_identical(
      res_first[["projection_method"]],
      "spmoran_nystrom"
    )
  }
)

testthat::test_that(
  ".compute_exact_spatial_mev_basis() preserves exact engine values",
  {
    mat_coords <-
      base::matrix(
        base::seq_len(10L),
        ncol = 2L
      )

    exact_function <- function(coords) {
      return(
        base::cbind(
          coords[, 1L],
          coords[, 2L],
          coords[, 1L] + coords[, 2L]
        )
      )
    }

    res <-
      .compute_exact_spatial_mev_basis(
        mat_coords = mat_coords,
        exact_function = exact_function
      )

    testthat::expect_equal(
      res[["mat_mev_all"]],
      exact_function(coords = mat_coords)
    )
    testthat::expect_null(res[["list_fast_basis"]])
    testthat::expect_identical(res[["engine_method"]], "sjsdm_exact")
    testthat::expect_identical(res[["projection_method"]], "idw")
  }
)

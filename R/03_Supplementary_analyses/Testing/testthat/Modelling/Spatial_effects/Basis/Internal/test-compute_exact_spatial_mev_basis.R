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

testthat::test_that(
  ".compute_exact_spatial_mev_basis() retains one positive eigenvector",
  {
    mat_coords <-
      base::matrix(
        base::c(
          5688.363, 5753.989, 5771.351, 5965.725, 5802.150,
          2322.188, 2401.035, 2307.708, 2140.048, 2468.313
        ),
        ncol = 2L
      )

    exact_function <- function(coords) {
      base::stop("argument of length 0")
    }

    res <-
      .compute_exact_spatial_mev_basis(
        mat_coords = mat_coords,
        exact_function = exact_function
      )

    testthat::expect_true(base::is.matrix(res[["mat_mev_all"]]))
    testthat::expect_identical(
      base::dim(res[["mat_mev_all"]]),
      base::c(5L, 1L)
    )
    testthat::expect_true(
      base::all(base::is.finite(res[["mat_mev_all"]]))
    )
    testthat::expect_identical(
      res[["engine_method"]],
      "sjsdm_exact_single_vector_compatibility"
    )
  }
)

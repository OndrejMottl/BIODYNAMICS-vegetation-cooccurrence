testthat::test_that(
  "compare_spatial_mev_subspaces() ignores signs and rotations",
  {
    mat_reference <-
      base::cbind(
        c(1, -1, 0, 0),
        c(0, 0, 1, -1)
      )

    rotation <-
      base::matrix(
        c(
          0, -1,
          1, 0
        ),
        nrow = 2L
      )

    mat_candidate <-
      mat_reference %*% rotation

    res <-
      compare_spatial_mev_subspaces(
        data_mev_reference = mat_reference,
        data_mev_candidate = mat_candidate
      )

    testthat::expect_equal(
      res[["mean_squared_canonical_correlation"]],
      1,
      tolerance = 1e-12
    )
    testthat::expect_equal(
      res[["maximum_principal_angle_degrees"]],
      0,
      tolerance = 2e-6
    )
  }
)

testthat::test_that(
  "compare_spatial_mev_subspaces() detects different subspaces",
  {
    mat_reference <-
      base::cbind(
        c(1, -1, 0, 0),
        c(0, 0, 1, -1)
      )

    mat_candidate <-
      base::cbind(
        c(1, 1, -1, -1),
        c(1, 1, 1, 1)
      )

    res <-
      compare_spatial_mev_subspaces(
        data_mev_reference = mat_reference,
        data_mev_candidate = mat_candidate
      )

    testthat::expect_lt(
      res[["mean_squared_canonical_correlation"]],
      1e-12
    )
    testthat::expect_equal(
      res[["maximum_principal_angle_degrees"]],
      90,
      tolerance = 1e-6
    )
  }
)

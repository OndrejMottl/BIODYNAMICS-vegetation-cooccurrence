testthat::test_that(
  "compute_shared_spatial_mev_basis() skips disabled spatial predictors",
  {
    res <-
      compute_shared_spatial_mev_basis(
        data_coords_projected = base::data.frame(),
        config_spatial_predictors = base::list(
          use_spatial = FALSE,
          spatial_mode = "spatial"
        ),
        compute_basis_function = function(...) {
          cli::cli_abort("Basis construction should not run.")
        }
      )

    testthat::expect_null(res)
  }
)

testthat::test_that(
  "compute_shared_spatial_mev_basis() forwards shared configuration",
  {
    compute_basis_function <- function(
        data_coords_projected,
        n_mev,
        strategy,
        exact_max_locations,
        fast_eigenvectors,
        fast_seed) {
      return(
        base::list(
          n_rows = base::nrow(data_coords_projected),
          n_mev = n_mev,
          strategy = strategy,
          exact_max_locations = exact_max_locations,
          fast_eigenvectors = fast_eigenvectors,
          fast_seed = fast_seed
        )
      )
    }

    res <-
      compute_shared_spatial_mev_basis(
        data_coords_projected = base::data.frame(
          coord_x_km = 1:4,
          coord_y_km = 5:8
        ),
        config_spatial_predictors = base::list(
          use_spatial = TRUE,
          spatial_mode = "spatial",
          n_mev = 3L,
          spatial_mev = base::list(
            strategy = "auto",
            exact_max_locations = 1999L,
            fast_eigenvectors = 200L,
            fast_seed = 900723L
          )
        ),
        compute_basis_function = compute_basis_function
      )

    testthat::expect_identical(
      res,
      base::list(
        n_rows = 4L,
        n_mev = 3L,
        strategy = "auto",
        exact_max_locations = 1999L,
        fast_eigenvectors = 200L,
        fast_seed = 900723L
      )
    )
  }
)

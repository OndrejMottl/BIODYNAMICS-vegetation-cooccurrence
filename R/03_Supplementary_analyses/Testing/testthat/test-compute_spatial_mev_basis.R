make_spatial_mev_basis_test_coords <- function() {
  res <-
    base::data.frame(
      coord_x_km = base::c(0, 10, 20, 30, 40),
      coord_y_km = base::c(0, 5, 15, 10, 25),
      row.names = base::letters[1:5]
    )

  return(res)
}

testthat::test_that(
  "compute_spatial_mev_basis() preserves exact public values",
  {
    data_coords <-
      make_spatial_mev_basis_test_coords()

    exact_function <- function(coords) {
      base::cbind(
        coords[, 1],
        coords[, 2],
        coords[, 1] + coords[, 2]
      )
    }

    res <-
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "exact",
        exact_max_locations = 10L,
        fast_eigenvectors = 4L,
        fast_seed = 900723L,
        exact_function = exact_function
      )

    testthat::expect_equal(
      res[["data_mev"]],
      base::data.frame(
        mev_1 = data_coords[["coord_x_km"]],
        mev_2 = data_coords[["coord_y_km"]],
        row.names = base::rownames(data_coords)
      )
    )
    testthat::expect_null(res[["projection_basis"]])
    testthat::expect_identical(
      res[["data_provenance"]][["strategy_selected"]],
      "exact"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev_basis() stores deterministic fast projection state",
  {
    data_coords <-
      make_spatial_mev_basis_test_coords()

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    fast_function <- function(
        coords,
        model,
        enum,
        threshold,
        interact) {
      environment_capture[["model"]] <- model
      environment_capture[["enum"]] <- enum
      environment_capture[["threshold"]] <- threshold
      environment_capture[["interact"]] <- interact

      mat_sf <-
        base::cbind(
          -base::seq_len(base::nrow(coords)),
          base::seq_len(base::nrow(coords)) * 2,
          base::seq_len(base::nrow(coords)) * 3
        )

      return(
        base::list(
          sf = mat_sf,
          ev = base::c(3, 2, 1),
          other = base::list(fast = 1)
        )
      )
    }

    res <-
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "fast",
        exact_max_locations = 10L,
        fast_eigenvectors = 3L,
        fast_seed = 900723L,
        fast_function = fast_function
      )

    testthat::expect_identical(environment_capture[["model"]], "exp")
    testthat::expect_identical(environment_capture[["enum"]], 3L)
    testthat::expect_identical(environment_capture[["threshold"]], 0)
    testthat::expect_false(environment_capture[["interact"]])
    testthat::expect_equal(
      res[["data_mev"]][["mev_1"]],
      base::seq_len(5L)
    )
    testthat::expect_identical(
      res[["projection_basis"]][["column_signs"]],
      base::c(-1, 1)
    )
    testthat::expect_identical(
      res[["data_provenance"]][["projection_method"]],
      "spmoran_nystrom"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev_basis() contains fast randomness locally",
  {
    data_coords <-
      make_spatial_mev_basis_test_coords()

    fast_function <- function(
        coords,
        model,
        enum,
        threshold,
        interact) {
      mat_sf <-
        base::matrix(
          stats::runif(base::nrow(coords) * 2L),
          ncol = 2L
        )

      return(
        base::list(
          sf = mat_sf,
          ev = base::c(2, 1),
          other = base::list(fast = 1)
        )
      )
    }

    base::set.seed(42)
    random_before <-
      stats::runif(1L)

    res_first <-
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "fast",
        exact_max_locations = 10L,
        fast_eigenvectors = 2L,
        fast_seed = 900723L,
        fast_function = fast_function
      )

    random_after <-
      stats::runif(1L)

    base::set.seed(42)
    testthat::expect_equal(random_before, stats::runif(1L))
    testthat::expect_equal(random_after, stats::runif(1L))

    res_second <-
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "fast",
        exact_max_locations = 10L,
        fast_eigenvectors = 2L,
        fast_seed = 900723L,
        fast_function = fast_function
      )

    testthat::expect_equal(
      res_first[["data_mev"]],
      res_second[["data_mev"]]
    )
  }
)

testthat::test_that(
  "compute_spatial_mev_basis() rejects non-finite coordinates",
  {
    data_coords <-
      make_spatial_mev_basis_test_coords()

    data_coords[["coord_x_km"]][[2L]] <- NA_real_

    testthat::expect_error(
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "exact",
        exact_max_locations = 10L,
        fast_eigenvectors = 3L,
        fast_seed = 900723L
      ),
      regexp = "finite"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev_basis() rejects insufficient fast support",
  {
    data_coords <-
      base::data.frame(
        coord_x_km = c(0, 0, 1, 1, 2),
        coord_y_km = c(0, 0, 1, 1, 2),
        row.names = base::letters[1:5]
      )

    testthat::expect_error(
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "fast",
        exact_max_locations = 10L,
        fast_eigenvectors = 3L,
        fast_seed = 900723L,
        fast_function = function(...) {
          cli::cli_abort("Fast function should not be called.")
        }
      ),
      regexp = "insufficient unique coordinates"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev_basis() rejects a non-Nystrom fast result",
  {
    data_coords <-
      base::data.frame(
        coord_x_km = c(0, 1, 2, 3, 4),
        coord_y_km = c(0, 1, 4, 9, 16),
        row.names = base::letters[1:5]
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
            base::seq_len(base::nrow(coords) * 2L),
            ncol = 2L
          ),
          other = base::list(fast = 0L)
        )
      )
    }

    testthat::expect_error(
      compute_spatial_mev_basis(
        data_coords_projected = data_coords,
        n_mev = 2L,
        strategy = "fast",
        exact_max_locations = 10L,
        fast_eigenvectors = 3L,
        fast_seed = 900723L,
        fast_function = fast_function
      ),
      regexp = "did not use Nyström"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when data_coords_projected is not a data frame",
  {
    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = "not_a_data_frame",
        n_mev = 2L
      ),
      regexp = "data_coords_projected must be a data frame"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when coord_y_km column is missing",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_C"),
        coord_x_km = c(100.0, 200.0, 300.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      ),
      regexp = "coord_x_km.*coord_y_km|coord_y_km"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when coord_x_km column is missing",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_C"),
        coord_y_km = c(400.0, 500.0, 600.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      ),
      regexp = "coord_x_km.*coord_y_km|coord_x_km"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when data_coords_projected has < 3 rows",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_C"),
        coord_x_km = c(100.0, 200.0, 300.0),
        coord_y_km = c(400.0, 400.0, 400.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 1L
      ),
      regexp = "more than 3 rows"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when n_mev is 0",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 200.0, 300.0, 150.0, 250.0),
        coord_y_km = c(400.0, 400.0, 400.0, 500.0, 500.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 0L
      ),
      regexp = "n_mev must be a single positive integer"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when n_mev is negative",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 200.0, 300.0, 150.0, 250.0),
        coord_y_km = c(400.0, 400.0, 400.0, 500.0, 500.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = -1L
      ),
      regexp = "n_mev must be a single positive integer"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() errors when n_mev is a character",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 200.0, 300.0, 150.0, 250.0),
        coord_y_km = c(400.0, 400.0, 400.0, 500.0, 500.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = "two"
      ),
      regexp = "n_mev must be a single positive integer"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() warns and clamps n_mev when > positive EVs",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    # well-spread sites produce 2 positive EVs;
    # requesting 3 must warn and clamp to 2
    res <-
      testthat::expect_warning(
        compute_spatial_mev(
          data_coords_projected = data_coords,
          n_mev = 3L
        ),
        regexp = "Lowering n_mev"
      )

    testthat::expect_equal(
      base::ncol(res),
      2L
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() returns a data frame (happy path)",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() result has exactly n_mev columns",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_equal(
      base::ncol(res),
      2L
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() result has columns named mev_1, mev_2",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_equal(
      base::colnames(res),
      c("mev_1", "mev_2")
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() result row names match input row names",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_equal(
      base::rownames(res),
      base::rownames(data_coords)
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() result has same nrow as input",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_equal(
      base::nrow(res),
      5L
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() result contains only finite values",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    vec_values <-
      base::unlist(res)

    testthat::expect_true(
      base::all(base::is.finite(vec_values))
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() with n_mev = 1 returns one column named mev_1",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 1L
      )

    testthat::expect_equal(
      base::ncol(res),
      1L
    )

    testthat::expect_equal(
      base::colnames(res),
      "mev_1"
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() accepts n_mev = 2 (maximum available) without error",
  {
    # well-spread sites produce 2 positive EVs; request 2 must succeed
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    res <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_equal(
      base::ncol(res),
      2L
    )
  }
)

testthat::test_that(
  "compute_spatial_mev() is reproducible with the same seed",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C", "site_D", "site_E"
        ),
        coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
        coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    base::set.seed(900723)
    res_1 <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    base::set.seed(900723)
    res_2 <-
      compute_spatial_mev(
        data_coords_projected = data_coords,
        n_mev = 2L
      )

    testthat::expect_equal(res_1, res_2)
  }
)

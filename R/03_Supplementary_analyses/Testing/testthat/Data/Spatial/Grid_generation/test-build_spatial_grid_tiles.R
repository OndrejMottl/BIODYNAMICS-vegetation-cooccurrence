testthat::test_that(
  "build_spatial_grid_tiles() clips and identifies regular tiles",
  {
    data_tiles <-
      build_spatial_grid_tiles(
        parent_scale_id = "europe",
        x_minimum_parent = -10,
        x_maximum_parent = 40,
        y_minimum_parent = 35,
        y_maximum_parent = 70,
        tile_size_degrees = 20,
        scale_name = "regional",
        scale_id_prefix = "eu_r"
      )

    testthat::expect_named(
      data_tiles,
      c(
        "scale_id",
        "scale",
        "parent_id",
        "x_min",
        "x_max",
        "y_min",
        "y_max"
      )
    )
    testthat::expect_equal(base::nrow(data_tiles), 9L)
    testthat::expect_equal(
      data_tiles[1, ],
      tibble::tibble(
        scale_id = "eu_r001",
        scale = "regional",
        parent_id = "europe",
        x_min = -10,
        x_max = 0,
        y_min = 35,
        y_max = 40
      )
    )
    testthat::expect_equal(
      data_tiles[9, ],
      tibble::tibble(
        scale_id = "eu_r009",
        scale = "regional",
        parent_id = "europe",
        x_min = 20,
        x_max = 40,
        y_min = 60,
        y_max = 70
      )
    )
  }
)


testthat::test_that(
  "build_spatial_grid_tiles() handles bounds within one tile",
  {
    data_tiles <-
      build_spatial_grid_tiles(
        parent_scale_id = "unit_a",
        x_minimum_parent = 1,
        x_maximum_parent = 4,
        y_minimum_parent = 2,
        y_maximum_parent = 3,
        tile_size_degrees = 5,
        scale_name = "local",
        scale_id_prefix = "unit_a_l"
      )

    testthat::expect_equal(base::nrow(data_tiles), 1L)
    testthat::expect_equal(
      dplyr::pull(data_tiles, scale_id),
      "unit_a_l001"
    )
    testthat::expect_equal(
      dplyr::select(
        data_tiles,
        "x_min",
        "x_max",
        "y_min",
        "y_max"
      ),
      tibble::tibble(
        x_min = 1,
        x_max = 4,
        y_min = 2,
        y_max = 3
      )
    )
  }
)


testthat::test_that(
  "build_spatial_grid_tiles() rejects invalid contracts",
  {
    testthat::expect_error(
      build_spatial_grid_tiles(
        parent_scale_id = "unit_a",
        x_minimum_parent = 4,
        x_maximum_parent = 1,
        y_minimum_parent = 2,
        y_maximum_parent = 3,
        tile_size_degrees = 5,
        scale_name = "local",
        scale_id_prefix = "unit_a_l"
      ),
      regexp = "x_minimum_parent"
    )
    testthat::expect_error(
      build_spatial_grid_tiles(
        parent_scale_id = "unit_a",
        x_minimum_parent = 1,
        x_maximum_parent = 4,
        y_minimum_parent = 2,
        y_maximum_parent = 3,
        tile_size_degrees = 0,
        scale_name = "local",
        scale_id_prefix = "unit_a_l"
      ),
      regexp = "tile_size_degrees"
    )
    testthat::expect_error(
      build_spatial_grid_tiles(
        parent_scale_id = "",
        x_minimum_parent = 1,
        x_maximum_parent = 4,
        y_minimum_parent = 2,
        y_maximum_parent = 3,
        tile_size_degrees = 5,
        scale_name = "local",
        scale_id_prefix = "unit_a_l"
      ),
      regexp = "parent_scale_id"
    )
  }
)

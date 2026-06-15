testthat::test_that(
  "build_land_prediction_grid() creates land-masked grid",
  {
    file_grid <-
      base::tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale = "continental",
        scale_id = "test_unit",
        x_min = 0,
        x_max = 1,
        y_min = 0,
        y_max = 1,
        continent_id = "test_unit"
      ),
      file = file_grid
    )

    polygon_land <-
      sf::st_polygon(
        x = base::list(
          base::matrix(
            data = c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0),
            ncol = 2,
            byrow = TRUE
          )
        )
      ) |>
      sf::st_sfc(crs = 4326) |>
      sf::st_sf()

    res <-
      build_land_prediction_grid(
        scale_id = "test_unit",
        grid_resolution = 1,
        target_crs = 3035L,
        path_spatial_grid = file_grid,
        land_polygons = polygon_land
      )

    testthat::expect_named(
      res,
      c("data_grid", "data_grid_coords_projected", "x_lim", "y_lim")
    )
    testthat::expect_true(base::nrow(res[["data_grid"]]) > 0L)
    testthat::expect_true(
      base::all(
        c("coord_x_km", "coord_y_km") %in%
          base::colnames(res[["data_grid_coords_projected"]])
      )
    )
  }
)

testthat::test_that(
  "build_land_prediction_grid() errors when no land cells remain",
  {
    file_grid <-
      base::tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale = "continental",
        scale_id = "test_unit",
        x_min = 0,
        x_max = 1,
        y_min = 0,
        y_max = 1,
        continent_id = "test_unit"
      ),
      file = file_grid
    )

    polygon_ocean <-
      sf::st_polygon(
        x = base::list(
          base::matrix(
            data = c(10, 10, 11, 10, 11, 11, 10, 11, 10, 10),
            ncol = 2,
            byrow = TRUE
          )
        )
      ) |>
      sf::st_sfc(crs = 4326) |>
      sf::st_sf()

    testthat::expect_error(
      build_land_prediction_grid(
        scale_id = "test_unit",
        grid_resolution = 1,
        target_crs = 3035L,
        path_spatial_grid = file_grid,
        land_polygons = polygon_ocean
      ),
      regexp = "has no cells"
    )
  }
)

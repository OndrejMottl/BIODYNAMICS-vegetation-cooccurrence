testthat::test_that(
  "extract_prediction_climate() extracts raster values for grid cells",
  {
    rast_test <-
      terra::rast(
        nrows = 2,
        ncols = 2,
        xmin = 0,
        xmax = 2,
        ymin = 0,
        ymax = 2,
        vals = c(1, 2, 3, 4)
      )

    raster_fn <- function(chelsa_var, age, x_lim, y_lim, cache_dir) {
      return(rast_test + base::as.numeric(chelsa_var == "bio2"))
    }

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(0.5, 1.5),
        coord_lat = c(0.5, 1.5)
      )

    res <-
      extract_prediction_climate(
        data_grid = data_grid,
        age = 500,
        abiotic_variables = c("bio1", "bio2"),
        x_lim = c(0, 2),
        y_lim = c(0, 2),
        cache_dir = base::tempdir(),
        raster_fn = raster_fn
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true(
      base::all(c("bio1", "bio2", "age") %in% base::colnames(res))
    )
    testthat::expect_equal(base::unique(dplyr::pull(res, age)), 500)
  }
)

testthat::test_that(
  "extract_prediction_climate() validates required grid columns",
  {
    rast_test <-
      terra::rast(
        nrows = 2,
        ncols = 2,
        xmin = 0,
        xmax = 2,
        ymin = 0,
        ymax = 2,
        vals = c(1, 2, 3, 4)
      )

    raster_fn <- function(chelsa_var, age, x_lim, y_lim, cache_dir) {
      return(rast_test)
    }

    data_grid <-
      tibble::tibble(
        coord_long = c(0.5, 1.5),
        coord_lat = c(0.5, 1.5)
      )

    testthat::expect_error(
      extract_prediction_climate(
        data_grid = data_grid,
        age = 500,
        abiotic_variables = c("bio1", "bio2"),
        x_lim = c(0, 2),
        y_lim = c(0, 2),
        cache_dir = base::tempdir(),
        raster_fn = raster_fn
      ),
      regexp = "must contain"
    )
  }
)

testthat::test_that(
  "extract_prediction_climate() validates cache directory",
  {
    rast_test <-
      terra::rast(
        nrows = 2,
        ncols = 2,
        xmin = 0,
        xmax = 2,
        ymin = 0,
        ymax = 2,
        vals = c(1, 2, 3, 4)
      )

    raster_fn <- function(chelsa_var, age, x_lim, y_lim, cache_dir) {
      return(rast_test)
    }

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(0.5, 1.5),
        coord_lat = c(0.5, 1.5)
      )

    testthat::expect_error(
      extract_prediction_climate(
        data_grid = data_grid,
        age = 500,
        abiotic_variables = c("bio1", "bio2"),
        x_lim = c(0, 2),
        y_lim = c(0, 2),
        cache_dir = "path/that/does/not/exist",
        raster_fn = raster_fn
      ),
      regexp = "existing directory"
    )
  }
)

testthat::test_that("chelsa_var NULL is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = NULL,
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "chelsa_var must be a single character string"
  )
})

testthat::test_that("chelsa_var non-character is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = 1L,
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "chelsa_var must be a single character string"
  )
})

testthat::test_that("chelsa_var length > 1 is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = c("bio1", "bio6"),
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "chelsa_var must be a single character string"
  )
})

testthat::test_that("age NULL is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = NULL,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "age must be a single numeric or integer value"
  )
})

testthat::test_that("age character is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = "1000",
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "age must be a single numeric or integer value"
  )
})

testthat::test_that("age vector of length 2 is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = c(1000, 2000),
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "age must be a single numeric or integer value"
  )
})

testthat::test_that("x_lim NULL is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = NULL,
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "x_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("x_lim non-numeric is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c("10", "20"),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "x_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("x_lim length 1 is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "x_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("x_lim length 3 is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 15, 20),
      y_lim = c(45, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "x_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("y_lim NULL is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = NULL,
      cache_dir = base::tempdir()
    ),
    regexp = "y_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("y_lim non-numeric is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c("45", "55"),
      cache_dir = base::tempdir()
    ),
    regexp = "y_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("y_lim length 1 is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45),
      cache_dir = base::tempdir()
    ),
    regexp = "y_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("y_lim length 3 is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 50, 55),
      cache_dir = base::tempdir()
    ),
    regexp = "y_lim must be a numeric vector of length 2"
  )
})

testthat::test_that("cache_dir NULL is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = NULL
    ),
    regexp = "cache_dir must be a string path to an existing directory"
  )
})

testthat::test_that("cache_dir non-character is rejected", {
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = 123
    ),
    regexp = "cache_dir must be a string path to an existing directory"
  )
})

testthat::test_that("cache_dir non-existent path is rejected", {
  path_nonexistent <- base::file.path(
    base::tempdir(),
    "this_dir_does_not_exist_xyz123"
  )
  testthat::expect_error(
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = path_nonexistent
    ),
    regexp = "cache_dir must be a string path to an existing directory"
  )
})

testthat::test_that("cache hit returns SpatRaster without download", {
  testthat::skip_on_ci()

  dir_cache <-
    base::file.path(base::tempdir(), "chelsa_cache_test")
  base::dir.create(dir_cache, showWarnings = FALSE)

  # Build a tiny 2x2 raster and write it to the expected cache path
  rast_fake <-
    terra::rast(
      nrows = 2L,
      ncols = 2L,
      xmin = 10,
      xmax = 20,
      ymin = 45,
      ymax = 55,
      crs = "EPSG:4326",
      vals = c(280, 282, 281, 283)
    )

  path_cache <-
    base::file.path(dir_cache, "bio1_1000.tif")

  terra::writeRaster(
    rast_fake,
    filename = path_cache,
    overwrite = TRUE
  )

  result <-
    get_chelsa_raster(
      chelsa_var = "bio1",
      age = 1000,
      x_lim = c(10, 20),
      y_lim = c(45, 55),
      cache_dir = dir_cache
    )

  testthat::expect_true(
    base::inherits(result, "SpatRaster")
  )

  # Clean up
  base::unlink(dir_cache, recursive = TRUE)
})

testthat::test_that("get_spatial_window returns correct list structure", {
  temp_csv <-
    tempfile(fileext = ".csv")

  readr::write_csv(
    x = tibble::tibble(
      scale_id = c("europe", "test_unit"),
      scale = c("continental", "regional"),
      parent_id = c(NA_character_, "europe"),
      x_min = c(-10, 0),
      x_max = c(40, 20),
      y_min = c(35, 40),
      y_max = c(70, 60)
    ),
    file = temp_csv
  )

  res <-
    get_spatial_window(scale_id = "europe", file = temp_csv)

  testthat::expect_type(res, "list")
  testthat::expect_named(res, c("x_lim", "y_lim"))

  base::unlink(temp_csv)
})

testthat::test_that("get_spatial_window returns numeric vectors of length 2", {
  temp_csv <-
    tempfile(fileext = ".csv")

  readr::write_csv(
    x = tibble::tibble(
      scale_id = "europe",
      scale = "continental",
      parent_id = NA_character_,
      x_min = -10,
      x_max = 40,
      y_min = 35,
      y_max = 70
    ),
    file = temp_csv
  )

  res <-
    get_spatial_window(scale_id = "europe", file = temp_csv)

  testthat::expect_type(res$x_lim, "double")
  testthat::expect_type(res$y_lim, "double")
  testthat::expect_length(res$x_lim, 2)
  testthat::expect_length(res$y_lim, 2)

  base::unlink(temp_csv)
})

testthat::test_that("get_spatial_window returns correct bounding box values", {
  temp_csv <-
    tempfile(fileext = ".csv")

  readr::write_csv(
    x = tibble::tibble(
      scale_id = "europe",
      scale = "continental",
      parent_id = NA_character_,
      x_min = -10,
      x_max = 40,
      y_min = 35,
      y_max = 70
    ),
    file = temp_csv
  )

  res <-
    get_spatial_window(scale_id = "europe", file = temp_csv)

  testthat::expect_equal(res$x_lim, c(-10, 40))
  testthat::expect_equal(res$y_lim, c(35, 70))

  base::unlink(temp_csv)
})

testthat::test_that("get_spatial_window errors on unknown scale_id", {
  temp_csv <-
    tempfile(fileext = ".csv")

  readr::write_csv(
    x = tibble::tibble(
      scale_id = "europe",
      scale = "continental",
      parent_id = NA_character_,
      x_min = -10,
      x_max = 40,
      y_min = 35,
      y_max = 70
    ),
    file = temp_csv
  )

  testthat::expect_error(
    get_spatial_window(scale_id = "nonexistent", file = temp_csv)
  )

  base::unlink(temp_csv)
})

testthat::test_that("get_spatial_window errors on non-character scale_id", {
  temp_csv <-
    tempfile(fileext = ".csv")

  readr::write_csv(
    x = tibble::tibble(
      scale_id = "europe",
      scale = "continental",
      parent_id = NA_character_,
      x_min = -10,
      x_max = 40,
      y_min = 35,
      y_max = 70
    ),
    file = temp_csv
  )

  testthat::expect_error(
    get_spatial_window(scale_id = 42, file = temp_csv)
  )
  testthat::expect_error(
    get_spatial_window(scale_id = c("europe", "n_america"), file = temp_csv)
  )

  base::unlink(temp_csv)
})

testthat::test_that("get_spatial_window errors on unreadable file", {
  testthat::expect_error(
    get_spatial_window(
      scale_id = "europe",
      file = "nonexistent_path/grid.csv"
    )
  )
})

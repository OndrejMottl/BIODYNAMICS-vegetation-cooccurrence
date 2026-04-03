# Input Validation -----

testthat::test_that("error if path_spatial_grid is not character", {
  testthat::expect_error(
    load_continental_rows(
      path_spatial_grid = 123L
    )
  )
})

testthat::test_that("error if path_spatial_grid has length > 1", {
  testthat::expect_error(
    load_continental_rows(
      path_spatial_grid = base::c("file1.csv", "file2.csv")
    )
  )
})

testthat::test_that("error if path_spatial_grid file does not exist", {
  testthat::expect_error(
    load_continental_rows(
      path_spatial_grid = "non_existent_file_xyz.csv"
    )
  )
})

testthat::test_that("error if CSV has no scale column", {
  data_no_scale <-
    tibble::tibble(
      scale_id = base::c("europe", "asia"),
      x_min = base::c(-30, 25),
      x_max = base::c(45, 180)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_no_scale,
    file = path_temp
  )

  testthat::expect_error(
    load_continental_rows(path_spatial_grid = path_temp)
  )

  base::unlink(path_temp)
})

testthat::test_that("error if CSV has scale column but no continental rows", {
  data_no_continental <-
    tibble::tibble(
      scale_id = base::c("europe", "asia"),
      scale = base::c("regional", "local"),
      x_min = base::c(-30, 25),
      x_max = base::c(45, 180)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_no_continental,
    file = path_temp
  )

  testthat::expect_error(
    load_continental_rows(path_spatial_grid = path_temp)
  )

  base::unlink(path_temp)
})


# Output Structure -----

testthat::test_that("result is a data frame when input is valid", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia"),
      scale = base::c("continental", "continental"),
      x_min = base::c(-30, 25),
      x_max = base::c(45, 180),
      y_min = base::c(35, 10),
      y_max = base::c(72, 80)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  testthat::expect_s3_class(res, "data.frame")

  base::unlink(path_temp)
})

testthat::test_that("result contains the scale column", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia"),
      scale = base::c("continental", "continental"),
      x_min = base::c(-30, 25),
      x_max = base::c(45, 180),
      y_min = base::c(35, 10),
      y_max = base::c(72, 80)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  testthat::expect_true(
    "scale" %in% base::colnames(res)
  )

  base::unlink(path_temp)
})

testthat::test_that("all rows in result have scale == continental", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia"),
      scale = base::c("continental", "continental"),
      x_min = base::c(-30, 25),
      x_max = base::c(45, 180),
      y_min = base::c(35, 10),
      y_max = base::c(72, 80)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  vec_scale <-
    dplyr::pull(res, scale)

  testthat::expect_true(
    base::all(vec_scale == "continental")
  )

  base::unlink(path_temp)
})


# Functional Correctness -----

testthat::test_that("only continental rows returned from mixed input", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia", "czechia"),
      scale = base::c("continental", "regional", "continental"),
      x_min = base::c(-30, 25, 12),
      x_max = base::c(45, 180, 18),
      y_min = base::c(35, 10, 49),
      y_max = base::c(72, 80, 51)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  testthat::expect_equal(
    base::nrow(res),
    2L
  )

  base::unlink(path_temp)
})

testthat::test_that("row count equals actual continental count in input", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia", "local_1", "local_2"),
      scale = base::c(
        "continental", "regional", "continental", "local"
      ),
      x_min = base::c(-30, 25, 12, 14),
      x_max = base::c(45, 180, 18, 16)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  testthat::expect_equal(
    base::nrow(res),
    2L
  )

  base::unlink(path_temp)
})

testthat::test_that("non-continental scale values are not in result", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia", "czechia"),
      scale = base::c("continental", "regional", "local"),
      x_min = base::c(-30, 25, 12),
      x_max = base::c(45, 180, 18)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  vec_scale <-
    dplyr::pull(res, scale)

  testthat::expect_false(
    "regional" %in% vec_scale
  )

  testthat::expect_false(
    "local" %in% vec_scale
  )

  base::unlink(path_temp)
})

testthat::test_that("exactly one continental row returns 1-row data frame", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "czechia"),
      scale = base::c("continental", "regional"),
      x_min = base::c(-30, 12),
      x_max = base::c(45, 18)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  testthat::expect_equal(
    base::nrow(res),
    1L
  )

  base::unlink(path_temp)
})

testthat::test_that("all original columns are preserved in result", {
  data_grid <-
    tibble::tibble(
      scale_id = base::c("europe", "asia"),
      scale = base::c("continental", "regional"),
      x_min = base::c(-30, 25),
      x_max = base::c(45, 180),
      y_min = base::c(35, 10),
      y_max = base::c(72, 80)
    )

  path_temp <- base::tempfile(fileext = ".csv")

  readr::write_csv(
    x = data_grid,
    file = path_temp
  )

  res <-
    load_continental_rows(path_spatial_grid = path_temp)

  vec_expected_cols <-
    base::c("scale_id", "scale", "x_min", "x_max", "y_min", "y_max")

  testthat::expect_true(
    base::all(vec_expected_cols %in% base::colnames(res))
  )

  base::unlink(path_temp)
})

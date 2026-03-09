testthat::test_that(
  "scale_spatial_for_fit() errors if not a data frame",
  {
    testthat::expect_error(
      scale_spatial_for_fit(data_spatial = "not a df")
    )
    testthat::expect_error(
      scale_spatial_for_fit(
        data_spatial = base::list(coord_x_km = 1)
      )
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() errors if 0-row data frame",
  {
    data_empty <-
      tibble::tibble(
        coord_x_km = base::numeric(0),
        coord_y_km = base::numeric(0)
      )
    testthat::expect_error(
      scale_spatial_for_fit(data_spatial = data_empty)
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() errors if 0-column data frame",
  {
    data_no_cols <-
      tibble::tibble(
        .row_name = c("A__0", "B__0")
      ) |>
      tibble::column_to_rownames(".row_name")
    testthat::expect_error(
      scale_spatial_for_fit(data_spatial = data_no_cols)
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() returns a named list",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(4000.0, 5000.0),
        coord_y_km = c(2700.0, 3000.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    testthat::expect_true(
      base::is.list(res)
    )
    testthat::expect_true(
      base::all(
        c("data_spatial_scaled", "spatial_scale_attributes") %in%
          base::names(res)
      )
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() scaled element is a data frame",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(4000.0, 5000.0),
        coord_y_km = c(2700.0, 3000.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    testthat::expect_true(
      base::is.data.frame(
        purrr::pluck(res, "data_spatial_scaled")
      )
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() preserves row names",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__100"),
        coord_x_km = c(4000.0, 5000.0),
        coord_y_km = c(2700.0, 3000.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    scaled <-
      purrr::pluck(res, "data_spatial_scaled")
    testthat::expect_equal(
      base::rownames(scaled),
      c("A__0", "B__100")
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() preserves column names",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(4000.0, 5000.0),
        coord_y_km = c(2700.0, 3000.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    scaled <-
      purrr::pluck(res, "data_spatial_scaled")
    testthat::expect_true(
      "coord_x_km" %in% base::colnames(scaled)
    )
    testthat::expect_true(
      "coord_y_km" %in% base::colnames(scaled)
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() scaled values have mean near 0",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__0", "C__0"),
        coord_x_km = c(4000.0, 5000.0, 6000.0),
        coord_y_km = c(2700.0, 2900.0, 3100.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    scaled <-
      purrr::pluck(res, "data_spatial_scaled")
    testthat::expect_equal(
      base::mean(dplyr::pull(scaled, coord_x_km)),
      0,
      tolerance = 1e-10
    )
    testthat::expect_equal(
      base::mean(dplyr::pull(scaled, coord_y_km)),
      0,
      tolerance = 1e-10
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() attributes list has correct names",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(4000.0, 5000.0),
        coord_y_km = c(2700.0, 3000.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    attrs <-
      purrr::pluck(res, "spatial_scale_attributes")
    testthat::expect_true(
      "coord_x_km" %in% base::names(attrs)
    )
    testthat::expect_true(
      "coord_y_km" %in% base::names(attrs)
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() attributes contain center",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(4000.0, 5000.0),
        coord_y_km = c(2700.0, 3000.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    attrs <-
      purrr::pluck(res, "spatial_scale_attributes")
    center_x <-
      purrr::pluck(attrs, "coord_x_km", "scaled:center")
    testthat::expect_equal(
      center_x,
      4500.0
    )
  }
)

testthat::test_that(
  "scale_spatial_for_fit() single-row: centres only",
  {
    data_spatial <-
      tibble::tibble(
        .row_name = "A__0",
        coord_x_km = 4000.0,
        coord_y_km = 2700.0
      ) |>
      tibble::column_to_rownames(".row_name")
    res <-
      scale_spatial_for_fit(data_spatial = data_spatial)
    scaled <-
      purrr::pluck(res, "data_spatial_scaled")
    testthat::expect_equal(
      dplyr::pull(scaled, coord_x_km),
      0.0
    )
  }
)

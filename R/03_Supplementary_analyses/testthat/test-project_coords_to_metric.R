testthat::test_that(
  "project_coords_to_metric() errors if not a data frame",
  {
    testthat::expect_error(
      project_coords_to_metric(data_coords = "not a df")
    )
    testthat::expect_error(
      project_coords_to_metric(
        data_coords = list(coord_long = 1, coord_lat = 1)
      )
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() errors if required columns missing",
  {
    data_no_lat <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      project_coords_to_metric(data_coords = data_no_lat)
    )

    data_no_long <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      project_coords_to_metric(data_coords = data_no_long)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() errors if 0-row data frame",
  {
    data_empty <-
      tibble::tibble(
        coord_long = base::numeric(0),
        coord_lat = base::numeric(0)
      )
    testthat::expect_error(
      project_coords_to_metric(data_coords = data_empty)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() errors if target_crs invalid",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      project_coords_to_metric(
        data_coords = data_coords,
        target_crs = -1L
      )
    )
    testthat::expect_error(
      project_coords_to_metric(
        data_coords = data_coords,
        target_crs = "3035"
      )
    )
    testthat::expect_error(
      project_coords_to_metric(
        data_coords = data_coords,
        target_crs = NA_integer_
      )
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() returns a data frame",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "project_coords_to_metric() adds coord_x_km and coord_y_km",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_true("coord_x_km" %in% base::colnames(res))
    testthat::expect_true("coord_y_km" %in% base::colnames(res))
  }
)

testthat::test_that(
  "project_coords_to_metric() retains coord_long and coord_lat",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_true("coord_long" %in% base::colnames(res))
    testthat::expect_true("coord_lat" %in% base::colnames(res))
  }
)

testthat::test_that(
  "project_coords_to_metric() preserves row names",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_equal(
      base::rownames(res),
      base::rownames(data_coords)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() preserves number of rows",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_coords)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() coord values in expected range",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    x_km <-
      dplyr::pull(res, coord_x_km)
    y_km <-
      dplyr::pull(res, coord_y_km)
    testthat::expect_true(x_km >= 4000 && x_km <= 5500)
    testthat::expect_true(y_km >= 2600 && y_km <= 3300)
  }
)

testthat::test_that(
  "project_coords_to_metric() works with multiple rows",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_C"),
        coord_long = c(15.0, 20.0, 10.0),
        coord_lat = c(50.0, 48.0, 52.0)
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_equal(
      base::nrow(res),
      3L
    )
    testthat::expect_equal(
      base::rownames(res),
      c("site_A", "site_B", "site_C")
    )
    testthat::expect_true(
      base::all(!base::is.na(dplyr::pull(res, coord_x_km)))
    )
    testthat::expect_true(
      base::all(!base::is.na(dplyr::pull(res, coord_y_km)))
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() default CRS is 3035",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res_default <-
      project_coords_to_metric(data_coords = data_coords)
    res_explicit <-
      project_coords_to_metric(
        data_coords = data_coords,
        target_crs = 3035L
      )
    testthat::expect_equal(
      dplyr::pull(res_default, coord_x_km),
      dplyr::pull(res_explicit, coord_x_km)
    )
    testthat::expect_equal(
      dplyr::pull(res_default, coord_y_km),
      dplyr::pull(res_explicit, coord_y_km)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() different CRS gives different km values",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res_3035 <-
      project_coords_to_metric(
        data_coords = data_coords,
        target_crs = 3035L
      )
    # EASE-Grid 2.0 (global equal-area)
    res_6933 <-
      project_coords_to_metric(
        data_coords = data_coords,
        target_crs = 6933L
      )
    x_3035 <- dplyr::pull(res_3035, coord_x_km)
    x_6933 <- dplyr::pull(res_6933, coord_x_km)
    testthat::expect_false(
      base::isTRUE(base::all.equal(x_3035, x_6933))
    )
  }
)


testthat::test_that(
  "project_coords_to_metric() errors if required columns missing",
  {
    data_no_lat <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      project_coords_to_metric(data_coords = data_no_lat)
    )

    data_no_long <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      project_coords_to_metric(data_coords = data_no_long)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() errors if 0-row data frame",
  {
    data_empty <-
      tibble::tibble(
        coord_long = base::numeric(0),
        coord_lat = base::numeric(0)
      )
    testthat::expect_error(
      project_coords_to_metric(data_coords = data_empty)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() returns a data frame",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "project_coords_to_metric() adds coord_x_km and coord_y_km",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_true("coord_x_km" %in% base::colnames(res))
    testthat::expect_true("coord_y_km" %in% base::colnames(res))
  }
)

testthat::test_that(
  "project_coords_to_metric() retains coord_long and coord_lat",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_true("coord_long" %in% base::colnames(res))
    testthat::expect_true("coord_lat" %in% base::colnames(res))
  }
)

testthat::test_that(
  "project_coords_to_metric() preserves row names",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_equal(
      base::rownames(res),
      base::rownames(data_coords)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() preserves number of rows",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_coords)
    )
  }
)

testthat::test_that(
  "project_coords_to_metric() coord values in expected range",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    x_km <-
      dplyr::pull(res, coord_x_km)
    y_km <-
      dplyr::pull(res, coord_y_km)
    testthat::expect_true(x_km >= 4000 && x_km <= 5500)
    testthat::expect_true(y_km >= 2600 && y_km <= 3300)
  }
)

testthat::test_that(
  "project_coords_to_metric() works with multiple rows",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_C"),
        coord_long = c(15.0, 20.0, 10.0),
        coord_lat = c(50.0, 48.0, 52.0)
      ) |>
      tibble::column_to_rownames("dataset_name")
    res <-
      project_coords_to_metric(data_coords = data_coords)
    testthat::expect_equal(
      base::nrow(res),
      3L
    )
    testthat::expect_equal(
      base::rownames(res),
      c("site_A", "site_B", "site_C")
    )
    testthat::expect_true(
      base::all(!base::is.na(dplyr::pull(res, coord_x_km)))
    )
    testthat::expect_true(
      base::all(!base::is.na(dplyr::pull(res, coord_y_km)))
    )
  }
)

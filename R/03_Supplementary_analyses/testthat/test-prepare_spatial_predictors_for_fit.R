testthat::test_that(
  "prepare_spatial_predictors_for_fit() errors: not a data frame",
  {
    data_sample_ids <-
      tibble::tibble(
        dataset_name = "site_A",
        age = 0
      )
    testthat::expect_error(
      prepare_spatial_predictors_for_fit(
        data_spatial = "not a df",
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() errors: sample_ids not df",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = "not a df"
      )
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() errors: missing columns",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = tibble::tibble(dataset_name = "site_A")
      )
    )
    testthat::expect_error(
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = tibble::tibble(age = 0)
      )
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() errors: 0-row data_spatial",
  {
    data_spatial_empty <-
      tibble::tibble(
        coord_x_km = base::numeric(0)
      )
    data_sample_ids <-
      tibble::tibble(
        dataset_name = "site_A",
        age = 0
      )
    testthat::expect_error(
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial_empty,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() errors: 0-col data_spatial",
  {
    data_spatial_no_cols <-
      tibble::tibble(
        dataset_name = "site_A"
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = "site_A",
        age = 0
      )
    testthat::expect_error(
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial_no_cols,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() returns a data frame",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0,
        coord_y_km = 2800.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = "site_A",
        age = 100
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() rownames as dataset__age",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = "site_A",
        age = 0
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_equal(
      base::rownames(res),
      "site_A__0"
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() has correct columns",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0,
        coord_y_km = 2800.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = "site_A",
        age = 100
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_equal(
      base::ncol(res),
      2L
    )
    testthat::expect_true("coord_x_km" %in% base::colnames(res))
    testthat::expect_true("coord_y_km" %in% base::colnames(res))
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() sorted by name then age",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = c("site_B", "site_A"),
        coord_x_km = c(5000.0, 4500.0)
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_A"),
        age = c(200, 100, 0)
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_equal(
      base::rownames(res),
      c("site_A__0", "site_A__200", "site_B__100")
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() multiple ages per dataset",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = c("site_A", "site_A", "site_A"),
        age = c(0, 100, 200)
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_equal(
      base::nrow(res),
      3L
    )
    testthat::expect_equal(
      base::rownames(res),
      c("site_A__0", "site_A__100", "site_A__200")
    )
    testthat::expect_true(
      base::all(dplyr::pull(res, coord_x_km) == 4500.0)
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() drops rows with NA",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B"),
        coord_x_km = c(4500.0, NA)
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B"),
        age = c(0, 0)
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_equal(
      base::nrow(res),
      1L
    )
    testthat::expect_equal(
      base::rownames(res),
      "site_A__0"
    )
  }
)

testthat::test_that(
  "prepare_spatial_predictors_for_fit() drops unmatched datasets",
  {
    data_spatial <-
      tibble::tibble(
        dataset_name = "site_A",
        coord_x_km = 4500.0
      ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B"),
        age = c(0, 0)
      )
    res <-
      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial,
        data_sample_ids = data_sample_ids
      )
    testthat::expect_equal(
      base::nrow(res),
      1L
    )
    testthat::expect_false(
      "site_B__0" %in% base::rownames(res)
    )
  }
)

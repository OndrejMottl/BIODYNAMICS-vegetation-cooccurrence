testthat::test_that(
  "prepare_coords_for_fit() errors if coords is not a df",
  {
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      prepare_coords_for_fit(
        data_coords = "not_a_df",
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() errors if sample_ids not a df",
  {
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      prepare_coords_for_fit(
        data_coords = data_coords,
        data_sample_ids = 42L
      )
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() errors on missing coordinate cols",
  {
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      prepare_coords_for_fit(
        data_coords = data_coords,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() errors on missing sample_ids cols",
  {
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = "A"
    )
    testthat::expect_error(
      prepare_coords_for_fit(
        data_coords = data_coords,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() returns a data frame",
  {
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_coords_for_fit(
      data_coords = data_coords,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() output has coord_long and coord_lat",
  {
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_coords_for_fit(
      data_coords = data_coords,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      base::all(
        c("coord_long", "coord_lat") %in% base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() row names use dataset__age format",
  {
    data_coords <- tibble::tibble(
      dataset_name = c("SiteA", "SiteB"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = c("SiteA", "SiteB"),
      age = c(100, 200)
    )
    res <- prepare_coords_for_fit(
      data_coords = data_coords,
      data_sample_ids = data_sample_ids
    )
    vec_rn <- base::rownames(res)
    testthat::expect_true(
      "SiteA__100" %in% vec_rn
    )
    testthat::expect_true(
      "SiteB__200" %in% vec_rn
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() expands dataset to sample level",
  {
    # Site A has two ages -> should produce two rows
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 100)
    )
    res <- prepare_coords_for_fit(
      data_coords = data_coords,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_equal(base::nrow(res), 2L)
    vec_rn <- base::rownames(res)
    testthat::expect_true("A__0" %in% vec_rn)
    testthat::expect_true("A__100" %in% vec_rn)
  }
)

testthat::test_that(
  "prepare_coords_for_fit() rows sorted by dataset then age",
  {
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = c("B", "A", "A", "B"),
      age = c(100, 0, 100, 0)
    )
    res <- prepare_coords_for_fit(
      data_coords = data_coords,
      data_sample_ids = data_sample_ids
    )
    vec_rn <- base::rownames(res)
    testthat::expect_equal(
      vec_rn,
      c("A__0", "A__100", "B__0", "B__100")
    )
  }
)

testthat::test_that(
  "prepare_coords_for_fit() correct coord values per dataset",
  {
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 20.0),
      coord_lat = c(50.0, 55.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_coords_for_fit(
      data_coords = data_coords,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_equal(
      dplyr::pull(res["A__0", , drop = FALSE], coord_long),
      15.0
    )
    testthat::expect_equal(
      dplyr::pull(res["B__0", , drop = FALSE], coord_long),
      20.0
    )
  }
)

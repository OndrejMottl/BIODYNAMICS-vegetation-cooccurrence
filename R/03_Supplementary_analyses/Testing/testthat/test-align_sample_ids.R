testthat::test_that(
  "align_sample_ids() errors if community arg is not a data frame",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      align_sample_ids(
        data_community_long = "not_a_df",
        data_abiotic_long = data_abiotic,
        data_coords = data_coords
      )
    )
  }
)

testthat::test_that(
  "align_sample_ids() errors if abiotic arg is not a data frame",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      align_sample_ids(
        data_community_long = data_community,
        data_abiotic_long = 42L,
        data_coords = data_coords
      )
    )
  }
)

testthat::test_that(
  "align_sample_ids() errors if coords arg is not a data frame",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      align_sample_ids(
        data_community_long = data_community,
        data_abiotic_long = data_abiotic,
        data_coords = base::list()
      )
    )
  }
)

testthat::test_that(
  "align_sample_ids() errors on missing columns in community",
  {
    data_community <- tibble::tibble(
      dataset_name = "A"
    )
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      align_sample_ids(
        data_community_long = data_community,
        data_abiotic_long = data_abiotic,
        data_coords = data_coords
      )
    )
  }
)

testthat::test_that(
  "align_sample_ids() errors on missing columns in abiotic",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_abiotic <- tibble::tibble(
      age = 0
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      align_sample_ids(
        data_community_long = data_community,
        data_abiotic_long = data_abiotic,
        data_coords = data_coords
      )
    )
  }
)

testthat::test_that(
  "align_sample_ids() errors if subset_age is not numeric",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    testthat::expect_error(
      align_sample_ids(
        data_community_long = data_community,
        data_abiotic_long = data_abiotic,
        data_coords = data_coords,
        subset_age = "zero"
      )
    )
  }
)

testthat::test_that(
  "align_sample_ids() returns df with dataset_name and age",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "A", "B", "B"),
      age = c(0, 100, 0, 100),
      taxon = c("Pinus", "Betula", "Pinus", "Quercus"),
      pollen_prop = c(0.5, 0.3, 0.2, 0.8)
    )
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "A", "B", "B"),
      age = c(0, 100, 0, 100),
      abiotic_variable_name = "temp",
      abiotic_value = c(10, 12, 8, 9)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    res <- align_sample_ids(
      data_community_long = data_community,
      data_abiotic_long = data_abiotic,
      data_coords = data_coords
    )
    testthat::expect_true(
      base::is.data.frame(res)
    )
    testthat::expect_true(
      base::all(
        c("dataset_name", "age") %in% base::colnames(res)
      )
    )
    testthat::expect_equal(base::nrow(res), 4L)
  }
)

testthat::test_that(
  "align_sample_ids() returns only the three-way intersection",
  {
    # C is in community but not abiotic -> excluded
    data_community <- tibble::tibble(
      dataset_name = c("A", "C"),
      age = c(0, 0),
      taxon = "Pinus",
      pollen_prop = 0.5
    )
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0),
      abiotic_variable_name = "temp",
      abiotic_value = c(10, 8)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    res <- align_sample_ids(
      data_community_long = data_community,
      data_abiotic_long = data_abiotic,
      data_coords = data_coords
    )
    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, dataset_name),
      "A"
    )
  }
)

testthat::test_that(
  "align_sample_ids() result is ordered by dataset_name then age",
  {
    data_community <- tibble::tibble(
      dataset_name = c("B", "A", "A", "B"),
      age = c(100, 0, 100, 0),
      taxon = "Pinus",
      pollen_prop = 0.5
    )
    data_abiotic <- tibble::tibble(
      dataset_name = c("B", "A", "A", "B"),
      age = c(100, 0, 100, 0),
      abiotic_variable_name = "temp",
      abiotic_value = c(9, 10, 12, 8)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("A", "B"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames("dataset_name")
    res <- align_sample_ids(
      data_community_long = data_community,
      data_abiotic_long = data_abiotic,
      data_coords = data_coords
    )
    vec_names <- dplyr::pull(res, dataset_name)
    vec_ages <- dplyr::pull(res, age)
    testthat::expect_equal(
      vec_names,
      c("A", "A", "B", "B")
    )
    testthat::expect_equal(
      vec_ages,
      c(0, 100, 0, 100)
    )
  }
)

testthat::test_that(
  "align_sample_ids() subset_age filters to matching ages",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 100),
      taxon = "Pinus",
      pollen_prop = 0.5
    )
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 100),
      abiotic_variable_name = "temp",
      abiotic_value = c(10, 12)
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    res <- align_sample_ids(
      data_community_long = data_community,
      data_abiotic_long = data_abiotic,
      data_coords = data_coords,
      subset_age = 0
    )
    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, age),
      0
    )
  }
)

testthat::test_that(
  "align_sample_ids() returns empty df when no intersection",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      taxon = "Pinus",
      pollen_prop = 0.5
    )
    data_abiotic <- tibble::tibble(
      dataset_name = "B",
      age = 0,
      abiotic_variable_name = "temp",
      abiotic_value = 10
    )
    data_coords <- tibble::tibble(
      dataset_name = "A",
      coord_long = 15.0,
      coord_lat = 50.0
    ) |>
      tibble::column_to_rownames("dataset_name")
    res <- align_sample_ids(
      data_community_long = data_community,
      data_abiotic_long = data_abiotic,
      data_coords = data_coords
    )
    testthat::expect_equal(base::nrow(res), 0L)
  }
)

# Side Effects

testthat::test_that(
  "align_sample_ids() emits no warnings for valid inputs",
  {
    data_community <-
      tibble::tibble(
        dataset_name = c("A", "A"),
        age = c(0, 100),
        taxon = "Pinus",
        pollen_prop = 0.5
      )
    data_abiotic <-
      tibble::tibble(
        dataset_name = c("A", "A"),
        age = c(0, 100),
        abiotic_variable_name = "temp",
        abiotic_value = c(10, 12)
      )
    data_coords <-
      tibble::tibble(
        dataset_name = "A",
        coord_long = 15.0,
        coord_lat = 50.0
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_no_warning(
      align_sample_ids(
        data_community_long = data_community,
        data_abiotic_long = data_abiotic,
        data_coords = data_coords
      )
    )
  }
)

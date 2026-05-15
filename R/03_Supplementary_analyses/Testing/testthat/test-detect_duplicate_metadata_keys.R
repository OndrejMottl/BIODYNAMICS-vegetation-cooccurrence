testthat::test_that(
  "detect_duplicate_metadata_keys() validates inputs",
  {
    data_community <- tibble::tibble(dataset_name = "a")
    data_ages <- tibble::tibble(dataset_name = "a")
    data_coords <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      detect_duplicate_metadata_keys(
        data_source = data_community,
        data_sample_ages = data_ages,
        data_coordinates = data_coords
      ),
      regexp = "sample_name"
    )
  }
)


testthat::test_that(
  "detect_duplicate_metadata_keys() returns zero rows for unique keys",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      sample_name = c("s1", "s1"),
      age = c(0, 0),
      taxon = c("Abies", "Betula"),
      pollen_count = c(1, 2)
    )
    data_ages <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      sample_name = c("s1", "s1"),
      age = c(0, 0)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      coord_long = c(10, 11),
      coord_lat = c(50, 51)
    )

    res <- detect_duplicate_metadata_keys(
      data_source = data_community,
      data_sample_ages = data_ages,
      data_coordinates = data_coords
    )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_named(
      res,
      c(
        "source",
        "dataset_name",
        "sample_name",
        "age",
        "taxon",
        "n_records"
      )
    )
  }
)


testthat::test_that(
  "detect_duplicate_metadata_keys() reports duplicated keys",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      sample_name = c("s1", "s1"),
      age = c(0, 0),
      taxon = c("Abies", "Abies"),
      pollen_count = c(1, 1)
    )
    data_ages <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      sample_name = c("s1", "s1"),
      age = c(0, 0)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      coord_long = c(10, 10),
      coord_lat = c(50, 50)
    )

    res <- detect_duplicate_metadata_keys(
      data_source = data_community,
      data_sample_ages = data_ages,
      data_coordinates = data_coords
    )

    testthat::expect_equal(
      dplyr::pull(res, source),
      c("community_record", "sample_age", "coordinate")
    )
    testthat::expect_equal(dplyr::pull(res, n_records), c(2L, 2L, 2L))
  }
)

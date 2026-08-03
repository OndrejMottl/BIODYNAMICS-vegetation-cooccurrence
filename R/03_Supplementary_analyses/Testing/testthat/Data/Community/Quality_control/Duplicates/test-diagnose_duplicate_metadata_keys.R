testthat::test_that(
  "diagnose_duplicate_metadata_keys() validates inputs",
  {
    data_community <- tibble::tibble(dataset_name = "a")
    data_sample_ages <- tibble::tibble(dataset_name = "a")
    data_coordinates <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      diagnose_duplicate_metadata_keys(
        data_community = data_community,
        data_sample_ages = data_sample_ages,
        data_coordinates = data_coordinates
      ),
      regexp = "sample_name"
    )
  }
)


testthat::test_that(
  "diagnose_duplicate_metadata_keys() returns zero rows for unique keys",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      sample_name = c("s1", "s1"),
      age = c(0, 0),
      taxon = c("Abies", "Betula"),
      pollen_count = c(1, 2)
    )
    data_sample_ages <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      sample_name = c("s1", "s1"),
      age = c(0, 0)
    )
    data_coordinates <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      coord_long = c(10, 11),
      coord_lat = c(50, 51)
    )

    res_duplicate_metadata_keys <- diagnose_duplicate_metadata_keys(
      data_community = data_community,
      data_sample_ages = data_sample_ages,
      data_coordinates = data_coordinates
    )

    testthat::expect_s3_class(res_duplicate_metadata_keys, "tbl_df")
    testthat::expect_equal(base::nrow(res_duplicate_metadata_keys), 0L)
    testthat::expect_named(
      res_duplicate_metadata_keys,
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
  "diagnose_duplicate_metadata_keys() reports duplicated keys",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      sample_name = c("s1", "s1"),
      age = c(0, 0),
      taxon = c("Abies", "Abies"),
      pollen_count = c(1, 1)
    )
    data_sample_ages <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      sample_name = c("s1", "s1"),
      age = c(0, 0)
    )
    data_coordinates <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      coord_long = c(10, 10),
      coord_lat = c(50, 50)
    )

    res_duplicate_metadata_keys <- diagnose_duplicate_metadata_keys(
      data_community = data_community,
      data_sample_ages = data_sample_ages,
      data_coordinates = data_coordinates
    )

    testthat::expect_equal(
      dplyr::pull(res_duplicate_metadata_keys, source),
      c("community_record", "sample_age", "coordinate")
    )
    testthat::expect_equal(
      dplyr::pull(res_duplicate_metadata_keys, n_records),
      c(2L, 2L, 2L)
    )
  }
)

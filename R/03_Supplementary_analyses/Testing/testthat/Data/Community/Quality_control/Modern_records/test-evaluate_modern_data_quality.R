testthat::test_that(
  "evaluate_modern_data_quality() returns named report tables",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b", "site_b"),
      sample_name = c("s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0),
      taxon = c("Abies", "Betula", "Abies", "Betula"),
      pollen_count = c(1, 2, 1, 2)
    )
    data_sample_ages <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      sample_name = c("s1", "s1"),
      age = c(0, 0)
    )
    data_coordinates <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      coord_long = c(10, 10),
      coord_lat = c(50, 50)
    )

    res_modern_data_quality <- evaluate_modern_data_quality(
      data_community = data_community,
      data_sample_ages = data_sample_ages,
      data_coordinates = data_coordinates
    )

    testthat::expect_type(res_modern_data_quality, "list")
    testthat::expect_named(
      res_modern_data_quality,
      c(
        "data_duplicate_sites",
        "data_duplicate_communities",
        "data_duplicate_metadata_keys",
        "data_impossible_values",
        "data_summary"
      )
    )
    testthat::expect_s3_class(
      purrr::pluck(res_modern_data_quality, "data_summary"),
      "tbl_df"
    )
  }
)


testthat::test_that(
  "evaluate_modern_data_quality() aborts on impossible values",
  {
    data_community <- tibble::tibble(
      dataset_name = "site_a",
      sample_name = "s1",
      age = 0,
      taxon = "Abies",
      pollen_count = -1
    )
    data_sample_ages <- tibble::tibble(
      dataset_name = "site_a",
      sample_name = "s1",
      age = 0
    )
    data_coordinates <- tibble::tibble(
      dataset_name = "site_a",
      coord_long = 10,
      coord_lat = 50
    )

    testthat::expect_error(
      evaluate_modern_data_quality(
        data_community = data_community,
        data_sample_ages = data_sample_ages,
        data_coordinates = data_coordinates
      ),
      regexp = "impossible"
    )

    res_modern_data_quality <- evaluate_modern_data_quality(
      data_community = data_community,
      data_sample_ages = data_sample_ages,
      data_coordinates = data_coordinates,
      flag_abort_on_impossible_values = FALSE
    )

    testthat::expect_equal(
      base::nrow(
        purrr::pluck(res_modern_data_quality, "data_impossible_values")
      ),
      1L
    )
  }
)

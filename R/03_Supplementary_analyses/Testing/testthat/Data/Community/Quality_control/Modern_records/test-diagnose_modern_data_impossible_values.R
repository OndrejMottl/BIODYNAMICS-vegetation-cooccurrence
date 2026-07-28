testthat::test_that(
  "diagnose_modern_data_impossible_values() validates inputs",
  {
    data_community <- tibble::tibble(dataset_name = "a")
    data_coordinates <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      diagnose_modern_data_impossible_values(
        data_community = data_community,
        data_coordinates = data_coordinates
      ),
      regexp = "pollen_count"
    )
  }
)


testthat::test_that(
  "diagnose_modern_data_impossible_values() returns zero rows for valid data",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      sample_name = c("s1", "s1"),
      age = c(0, 0),
      taxon = c("Abies", "Betula"),
      pollen_count = c(1, 2)
    )
    data_coordinates <- tibble::tibble(
      dataset_name = "site_a",
      coord_long = 10,
      coord_lat = 50
    )

    res_impossible_values <- diagnose_modern_data_impossible_values(
      data_community = data_community,
      data_coordinates = data_coordinates
    )

    testthat::expect_s3_class(res_impossible_values, "tbl_df")
    testthat::expect_equal(base::nrow(res_impossible_values), 0L)
    testthat::expect_named(
      res_impossible_values,
      c("source", "issue", "dataset_name", "sample_name", "taxon", "value")
    )
  }
)


testthat::test_that(
  "diagnose_modern_data_impossible_values() handles empty inputs",
  {
    data_community <- tibble::tibble(
      dataset_name = base::character(),
      sample_name = base::character(),
      age = base::numeric(),
      taxon = base::character(),
      pollen_count = base::numeric()
    )
    data_coordinates <- tibble::tibble(
      dataset_name = base::character(),
      coord_long = base::numeric(),
      coord_lat = base::numeric()
    )

    res_impossible_values <- diagnose_modern_data_impossible_values(
      data_community = data_community,
      data_coordinates = data_coordinates
    )

    testthat::expect_s3_class(res_impossible_values, "tbl_df")
    testthat::expect_equal(base::nrow(res_impossible_values), 0L)
  }
)


testthat::test_that(
  "diagnose_modern_data_impossible_values() reports bad values",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b"),
      sample_name = c("s1", "s1", "s1"),
      age = c(0, 1, 0),
      taxon = c("Abies", "Betula", "Pinus"),
      pollen_count = c(-1, 2, Inf)
    )
    data_coordinates <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      coord_long = c(200, 11),
      coord_lat = c(50, NA_real_)
    )

    res_impossible_values <- diagnose_modern_data_impossible_values(
      data_community = data_community,
      data_coordinates = data_coordinates
    )

    testthat::expect_true(
      base::all(
        c(
          "negative_pollen_count",
          "non_finite_pollen_count",
          "non_zero_modern_age",
          "longitude_out_of_range",
          "missing_coordinate"
        ) %in% dplyr::pull(res_impossible_values, issue)
      )
    )
  }
)

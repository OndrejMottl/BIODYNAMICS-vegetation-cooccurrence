testthat::test_that(
  "diagnose_duplicate_sites() validates inputs",
  {
    testthat::expect_error(
      diagnose_duplicate_sites(data_coordinates = "not data"),
      regexp = "data_source"
    )

    data_coordinates_missing_columns <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      diagnose_duplicate_sites(
        data_coordinates = data_coordinates_missing_columns
      ),
      regexp = "coord_long"
    )
  }
)


testthat::test_that(
  "diagnose_duplicate_sites() returns zero rows without duplicates",
  {
    data_coordinates <- base::data.frame(
      coord_long = c(10, 11),
      coord_lat = c(50, 51)
    )
    base::rownames(data_coordinates) <- c("site_a", "site_b")

    res_duplicate_sites <- diagnose_duplicate_sites(
      data_coordinates = data_coordinates
    )

    testthat::expect_s3_class(res_duplicate_sites, "tbl_df")
    testthat::expect_equal(base::nrow(res_duplicate_sites), 0L)
    testthat::expect_named(
      res_duplicate_sites,
      c(
        "duplicate_site_group",
        "dataset_name",
        "coord_long",
        "coord_lat",
        "n_sites"
      )
    )
  }
)


testthat::test_that(
  "diagnose_duplicate_sites() reports all duplicated coordinate records",
  {
    data_coordinates <- tibble::tibble(
      dataset_name = c("site_b", "site_a", "site_c"),
      coord_long = c(10, 10, 11),
      coord_lat = c(50, 50, 51)
    )

    res_duplicate_sites <- diagnose_duplicate_sites(
      data_coordinates = data_coordinates
    )

    testthat::expect_equal(base::nrow(res_duplicate_sites), 2L)
    testthat::expect_equal(
      dplyr::pull(res_duplicate_sites, dataset_name),
      c("site_a", "site_b")
    )
    testthat::expect_equal(
      dplyr::pull(res_duplicate_sites, n_sites),
      c(2L, 2L)
    )
  }
)

testthat::test_that(
  "detect_duplicate_sites() validates inputs",
  {
    testthat::expect_error(
      detect_duplicate_sites(data_source = "not data"),
      regexp = "data_source"
    )

    data_missing <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      detect_duplicate_sites(data_source = data_missing),
      regexp = "coord_long"
    )
  }
)


testthat::test_that(
  "detect_duplicate_sites() returns zero rows without duplicates",
  {
    data_coords <- base::data.frame(
      coord_long = c(10, 11),
      coord_lat = c(50, 51)
    )
    base::rownames(data_coords) <- c("site_a", "site_b")

    res <- detect_duplicate_sites(data_source = data_coords)

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_named(
      res,
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
  "detect_duplicate_sites() reports all duplicated coordinate records",
  {
    data_coords <- tibble::tibble(
      dataset_name = c("site_b", "site_a", "site_c"),
      coord_long = c(10, 10, 11),
      coord_lat = c(50, 50, 51)
    )

    res <- detect_duplicate_sites(data_source = data_coords)

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      dplyr::pull(res, dataset_name),
      c("site_a", "site_b")
    )
    testthat::expect_equal(dplyr::pull(res, n_sites), c(2L, 2L))
  }
)

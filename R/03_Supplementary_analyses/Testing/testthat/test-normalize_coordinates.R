testthat::test_that(
  "normalize_coordinates() validates input type",
  {
    testthat::expect_error(
      normalize_coordinates(data_source = "not data"),
      regexp = "data_source"
    )
  }
)


testthat::test_that(
  "normalize_coordinates() uses dataset_name column",
  {
    data_coordinates <- tibble::tibble(
      dataset_name = "site_a",
      coord_long = 10,
      coord_lat = 50,
      extra = "x"
    )

    res <- normalize_coordinates(data_source = data_coordinates)

    testthat::expect_named(
      res,
      c("dataset_name", "coord_long", "coord_lat")
    )
    testthat::expect_equal(dplyr::pull(res, dataset_name), "site_a")
  }
)


testthat::test_that(
  "normalize_coordinates() uses row names when needed",
  {
    data_coordinates <- base::data.frame(
      coord_long = 10,
      coord_lat = 50
    )
    base::rownames(data_coordinates) <- "site_a"

    res <- normalize_coordinates(data_source = data_coordinates)

    testthat::expect_equal(dplyr::pull(res, dataset_name), "site_a")
  }
)

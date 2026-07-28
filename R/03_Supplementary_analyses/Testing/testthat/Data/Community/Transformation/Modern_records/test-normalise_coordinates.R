testthat::test_that(
  "normalise_coordinates() validates input type",
  {
    testthat::expect_error(
      normalise_coordinates(data_coordinates = "not data"),
      regexp = "data_coordinates"
    )
  }
)


testthat::test_that(
  "normalise_coordinates() uses dataset_name column",
  {
    data_coordinates <- tibble::tibble(
      dataset_name = "site_a",
      coord_long = 10,
      coord_lat = 50,
      extra = "x"
    )

    res_coordinates_normalised <-
      normalise_coordinates(data_coordinates = data_coordinates)

    testthat::expect_named(
      res_coordinates_normalised,
      c("dataset_name", "coord_long", "coord_lat")
    )
    testthat::expect_equal(
      dplyr::pull(res_coordinates_normalised, dataset_name),
      "site_a"
    )
  }
)


testthat::test_that(
  "normalise_coordinates() uses row names when needed",
  {
    data_coordinates <- base::data.frame(
      coord_long = 10,
      coord_lat = 50
    )
    base::rownames(data_coordinates) <- "site_a"

    res_coordinates_normalised <-
      normalise_coordinates(data_coordinates = data_coordinates)

    testthat::expect_equal(
      dplyr::pull(res_coordinates_normalised, dataset_name),
      "site_a"
    )
  }
)

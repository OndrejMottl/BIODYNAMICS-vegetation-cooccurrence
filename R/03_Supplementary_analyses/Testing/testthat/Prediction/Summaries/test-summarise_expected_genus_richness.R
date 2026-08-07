testthat::test_that(
  "summarise_expected_genus_richness() sums taxon probabilities",
  {
    data_predictions <-
      tibble::tibble(
        grid_id = c(1L, 1L, 2L, 2L),
        coord_long = c(10, 10, 11, 11),
        coord_lat = c(50, 50, 51, 51),
        age = c(0, 0, 0, 0),
        taxon = c("A", "B", "A", "B"),
        predicted_probability = c(0.2, 0.4, 0.7, 0.1)
      )

    res <-
      summarise_expected_genus_richness(
        data_predicted_long = data_predictions
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      dplyr::pull(res, expected_genus_richness),
      c(0.6, 0.8)
    )
    testthat::expect_equal(dplyr::pull(res, n_taxa), c(2L, 2L))
  }
)

testthat::test_that(
  "summarise_expected_genus_richness() validates inputs",
  {
    data_predictions <-
      tibble::tibble(
        grid_id = 1L,
        coord_long = 10,
        coord_lat = 50,
        age = 0,
        taxon = "A"
      )

    testthat::expect_error(
      summarise_expected_genus_richness(
        data_predicted_long = data_predictions
      ),
      regexp = "predicted_probability"
    )
  }
)

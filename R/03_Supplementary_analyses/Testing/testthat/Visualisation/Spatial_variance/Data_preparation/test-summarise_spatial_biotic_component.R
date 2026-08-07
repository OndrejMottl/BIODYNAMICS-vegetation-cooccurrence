testthat::test_that(
  "summarise_spatial_biotic_component() summarises associations",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 3)),
        resolution_label = base::rep("Genus", 3),
        component = base::c("Associations", "Associations", "Abiotic"),
        component_total_percentage = base::c(10, 30, 90)
      )

    res_data <-
      summarise_spatial_biotic_component(
        data_plot = data_plot
      )

    testthat::expect_equal(base::nrow(res_data), 1L)
    testthat::expect_equal(dplyr::pull(res_data, median), 20)
    testthat::expect_equal(dplyr::pull(res_data, lwr_95), 10.5)
    testthat::expect_equal(dplyr::pull(res_data, upr_95), 29.5)
  }
)

testthat::test_that(
  "summarise_spatial_biotic_component() validates inputs",
  {
    testthat::expect_error(
      summarise_spatial_biotic_component(
        data_plot = tibble::tibble(scale = "local")
      ),
      regexp = "data_plot"
    )
  }
)

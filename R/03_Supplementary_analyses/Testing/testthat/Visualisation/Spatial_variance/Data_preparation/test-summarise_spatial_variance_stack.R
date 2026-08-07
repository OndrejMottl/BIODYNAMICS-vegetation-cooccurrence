testthat::test_that(
  "summarise_spatial_variance_stack() adds unexplained share",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::c("local", "local")),
        resolution_label = base::c("Genus", "Genus"),
        component_label = base::c("Biotic co-occurrence", "Abiotic"),
        component_total_percentage = base::c(30, 40)
      )

    res_data <-
      summarise_spatial_variance_stack(
        data_plot = data_plot,
        vec_component_levels = base::c(
          "Biotic co-occurrence",
          "Abiotic",
          "Unexplained"
        )
      )

    data_unexplained <-
      res_data |>
      dplyr::filter(
        .data$component_label == "Unexplained"
      )

    testthat::expect_equal(base::nrow(res_data), 3L)
    testthat::expect_equal(
      dplyr::pull(data_unexplained, component_total_percentage),
      30
    )
  }
)

testthat::test_that(
  "summarise_spatial_variance_stack() validates inputs",
  {
    testthat::expect_error(
      summarise_spatial_variance_stack(
        data_plot = tibble::tibble(),
        vec_component_levels = "Abiotic"
      ),
      regexp = "Unexplained"
    )
  }
)

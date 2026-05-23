testthat::test_that(
  "plot_spatial_biotic_component() returns ggplot",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::c("local", "local")),
        resolution_label = base::c("Genus", "Genus"),
        component = base::c("Associations", "Associations"),
        component_total_percentage = base::c(10, 20)
      )

    data_biotic_summary <-
      tibble::tibble(
        scale = base::factor("local"),
        resolution_label = "Genus",
        median = 15,
        lwr_95 = 10,
        upr_95 = 20
      )

    res_plot <-
      plot_spatial_biotic_component(
        data_plot = data_plot,
        data_biotic_summary = data_biotic_summary,
        plot_title = "Test biotic"
      )

    testthat::expect_s3_class(res_plot, "ggplot")
  }
)

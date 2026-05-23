testthat::test_that(
  "plot_spatial_variance_stack() returns ggplot",
  {
    data_component_stack <-
      tibble::tibble(
        scale = base::factor("local"),
        resolution_label = "Genus",
        component_label = "Abiotic",
        component_total_percentage = 40
      )

    res_plot <-
      plot_spatial_variance_stack(
        data_component_stack = data_component_stack,
        plot_title = "Test stack",
        vec_component_colours = base::c("Abiotic" = "#D95F02")
      )

    testthat::expect_s3_class(res_plot, "ggplot")
  }
)

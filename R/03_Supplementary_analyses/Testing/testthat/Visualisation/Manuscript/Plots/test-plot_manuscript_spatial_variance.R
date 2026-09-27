testthat::test_that(
  "plot_manuscript_spatial_variance() returns one assembled figure",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor("local", levels = "local"),
        scale_id = "unit_a",
        resolution_label = base::factor("Genus", levels = "Genus"),
        component = "Associations",
        component_total_percentage = 30,
        continent_id = "europe"
      )
    data_component_summary <-
      tibble::tibble(
        scale = base::factor(
          base::rep("local", 4L),
          levels = "local"
        ),
        resolution_label = base::factor(
          base::rep("Genus", 4L),
          levels = "Genus"
        ),
        component_label = base::factor(
          base::c(
            "Biotic co-occurrence",
            "Climate",
            "Spatial",
            "Unexplained"
          ),
          levels = base::c(
            "Biotic co-occurrence",
            "Climate",
            "Spatial",
            "Unexplained"
          )
        ),
        component_total_percentage = base::c(30, 30, 20, 20)
      )
    data_biotic_summary <-
      tibble::tibble(
        scale = base::factor("local", levels = "local"),
        resolution_label = base::factor("Genus", levels = "Genus"),
        median = 30,
        lwr_95 = 25,
        upr_95 = 35
      )

    res_plot <-
      plot_manuscript_spatial_variance(
        data_plot,
        data_component_summary,
        data_biotic_summary
      )

    testthat::expect_true(
      base::inherits(res_plot, base::c("gg", "ggplot", "gtable"))
    )
  }
)

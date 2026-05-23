testthat::test_that(
  "plot_spatial_variance_waffle() returns ggplot",
  {
    data_waffle <-
      tibble::tibble(
        scale = base::factor("local"),
        resolution_label = "Genus",
        tile_col = 1L,
        tile_row = 1L,
        continent_id = "europe",
        point_colour = "#000000",
        R2_Nagelkerke_percentage = 20
      )

    res_plot <-
      plot_spatial_variance_waffle(
        data_waffle = data_waffle,
        plot_title = "Test waffle",
        vec_continent_shapes = base::c("europe" = 6)
      )

    testthat::expect_s3_class(res_plot, "ggplot")
  }
)

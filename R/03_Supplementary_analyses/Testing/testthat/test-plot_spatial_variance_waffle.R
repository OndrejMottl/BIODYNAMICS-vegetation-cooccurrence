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
        tile_fill_colour = "#4A8F73",
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

testthat::test_that(
  "plot_spatial_variance_waffle() can show optional fill legend",
  {
    data_waffle <-
      tibble::tibble(
        scale = base::factor("local"),
        resolution_label = "Genus",
        tile_col = 1L,
        tile_row = 1L,
        continent_id = "europe",
        tile_fill_colour = "#4A8F73",
        point_colour = "#000000",
        R2_Nagelkerke_percentage = 20
      )

    res_plot <-
      plot_spatial_variance_waffle(
        data_waffle = data_waffle,
        plot_title = "Test waffle",
        vec_continent_shapes = base::c("europe" = 6),
        flag_show_fill_legend = TRUE,
        vec_component_colours = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3",
          "Associations" = "#1B9E77"
        )
      )

    fill_scale <-
      res_plot$scales$get_scales("fill")

    testthat::expect_false(base::identical(fill_scale$guide, "none"))
  }
)

testthat::test_that(
  "plot_spatial_variance_waffle() validates legend colour mapping",
  {
    data_waffle <-
      tibble::tibble(
        scale = base::factor("local"),
        resolution_label = "Genus",
        tile_col = 1L,
        tile_row = 1L,
        continent_id = "europe",
        tile_fill_colour = "#4A8F73",
        point_colour = "#000000",
        R2_Nagelkerke_percentage = 20
      )

    testthat::expect_error(
      plot_spatial_variance_waffle(
        data_waffle = data_waffle,
        plot_title = "Test waffle",
        vec_continent_shapes = base::c("europe" = 6),
        flag_show_fill_legend = TRUE,
        vec_component_colours = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3"
        )
      ),
      regexp = "missing legend colours"
    )
  }
)

testthat::test_that(
  "plot_spatial_variance_waffle() supports triangle fill legend",
  {
    data_waffle <-
      tibble::tibble(
        scale = base::factor("local"),
        resolution_label = "Genus",
        tile_col = 1L,
        tile_row = 1L,
        continent_id = "europe",
        tile_fill_colour = "#4A8F73",
        point_colour = "#000000",
        R2_Nagelkerke_percentage = 20
      )

    res_plot <-
      plot_spatial_variance_waffle(
        data_waffle = data_waffle,
        plot_title = "Test waffle",
        vec_continent_shapes = base::c("europe" = 6),
        flag_show_fill_legend = TRUE,
        vec_component_colours = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3",
          "Associations" = "#1B9E77"
        ),
        fill_legend_style = "triangle"
      )

    testthat::expect_s3_class(res_plot, "ggplot")
  }
)

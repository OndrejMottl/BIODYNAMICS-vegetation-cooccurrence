testthat::test_that(
  "plot_manuscript_spatial_map_panel() shows available map data",
  {
    mat_polygon <-
      base::matrix(
        base::c(
          0, 0,
          3, 0,
          3, 3,
          0, 3,
          0, 0
        ),
        ncol = 2L,
        byrow = TRUE
      )
    sf_world <-
      sf::st_sf(
        geometry = sf::st_sfc(
          sf::st_polygon(base::list(mat_polygon)),
          crs = 4326
        )
      )
    data_map <-
      tibble::tibble(
        continent_id = base::rep("europe", 3L),
        scale = base::rep("local", 3L),
        scale_id = base::rep("unit_a", 3L),
        resolution_id = base::c(
          "genus",
          "family",
          "functional_type"
        ),
        x_min = base::rep(1, 3L),
        x_max = base::rep(2, 3L),
        y_min = base::rep(1, 3L),
        y_max = base::rep(2, 3L),
        glyph_x = base::c(1.27, 1.5, 1.73),
        glyph_y = base::rep(1.5, 3L),
        association_percentage = base::c(30, NA, NA),
        availability_status = base::c(
          "available",
          "expected_infeasible",
          "missing_model"
        )
      )

    res_plot <-
      plot_manuscript_spatial_map_panel(
        data_map = data_map,
        sf_world = sf_world,
        continent_id = "europe",
        scale_id = "local",
        panel_label = "Europe | Local"
      )

    testthat::expect_s3_class(res_plot, "ggplot")
    testthat::expect_identical(
      res_plot[["labels"]][["title"]],
      "Europe | Local"
    )
    testthat::expect_equal(
      res_plot[["labels"]][["subtitle"]],
      "1/3 fitted"
    )
    testthat::expect_equal(
      base::nrow(res_plot[["layers"]][[3L]][["data"]]),
      1L
    )
    testthat::expect_equal(
      base::nrow(res_plot[["layers"]][[4L]][["data"]]),
      2L
    )
  }
)

testthat::test_that(
  "plot_manuscript_spatial_map_panel() rejects empty panels",
  {
    sf_world <-
      sf::st_sf(
        geometry = sf::st_sfc(
          sf::st_point(base::c(0, 0)),
          crs = 4326
        )
      )
    data_map <-
      tibble::tibble(
        continent_id = "europe",
        scale = "local",
        scale_id = "unit_a",
        resolution_id = "genus",
        x_min = 1,
        x_max = 2,
        y_min = 1,
        y_max = 2,
        glyph_x = 1.5,
        glyph_y = 1.5,
        association_percentage = 30,
        availability_status = "available"
      )

    testthat::expect_error(
      plot_manuscript_spatial_map_panel(
        data_map = data_map,
        sf_world = sf_world,
        continent_id = "asia",
        scale_id = "local",
        panel_label = "missing"
      ),
      "at least one row"
    )
  }
)

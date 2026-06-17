testthat::test_that(
  "build_prediction_frame() returns ggplot",
  {
    data_frame <-
      tibble::tibble(
        age = c(2000, 2000, 1000, 1000),
        coord_long = c(10, 11, 10, 11),
        coord_lat = c(50, 50, 51, 51),
        predicted_probability = c(0.2, 0.4, 0.6, 0.8)
      )

    data_world <-
      tibble::tibble(
        long = c(9, 12, 12, 9),
        lat = c(49, 49, 52, 52),
        group = c(1, 1, 1, 1)
      )

    list_prediction_grid <-
      base::list(
        x_lim = c(9, 12),
        y_lim = c(49, 52)
      )

    vec_palette <-
      c(
        background = "#000000",
        border = "#333333",
        text = "#ffffff",
        muted = "#aaaaaa",
        cyan = "#00ffff",
        phosphor = "#66ff66",
        surface_alt = "#111111"
      )

    res <-
      build_prediction_frame(
        data_frame = data_frame,
        age_value = 2000,
        value_column = "predicted_probability",
        subtitle_label = "Taxon",
        fill_label = "Probability",
        fill_limits = c(0, 1),
        list_prediction_grid = list_prediction_grid,
        data_world = data_world,
        grid_resolution = 1,
        fill_colors = c("#000000", "#ffffff"),
        vec_palette = vec_palette,
        font_family = "sans"
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "build_prediction_frame() validates fill colours",
  {
    data_frame <-
      tibble::tibble(
        age = c(2000),
        coord_long = c(10),
        coord_lat = c(50),
        predicted_probability = c(0.2)
      )

    data_world <-
      tibble::tibble(
        long = c(9, 12, 12, 9),
        lat = c(49, 49, 52, 52),
        group = c(1, 1, 1, 1)
      )

    testthat::expect_error(
      build_prediction_frame(
        data_frame = data_frame,
        age_value = 2000,
        value_column = "predicted_probability",
        subtitle_label = "Taxon",
        fill_label = "Probability",
        fill_limits = c(0, 1),
        list_prediction_grid = base::list(
          x_lim = c(9, 12),
          y_lim = c(49, 52)
        ),
        data_world = data_world,
        grid_resolution = 1,
        fill_colors = "#000000"
      ),
      regexp = "fill_colors"
    )
  }
)

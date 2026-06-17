testthat::test_that(
  "save_prediction_animation() writes GIF",
  {
    path_output <-
      base::file.path(
        tempdir(),
        "test_save_prediction_animation"
      )

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

    data_points <-
      tibble::tibble(
        age = c(2000, 1000),
        coord_long = c(10.5, 10.5),
        coord_lat = c(50.5, 50.5)
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
      save_prediction_animation(
        data_frame = data_frame,
        value_column = "predicted_probability",
        subtitle_label = "Taxon",
        fill_label = "Probability",
        fill_limits = c(0, 1),
        vec_age_slices = c(2000, 1000),
        path_output = path_output,
        list_prediction_grid = list_prediction_grid,
        data_world = data_world,
        grid_resolution = 1,
        time_step = 1000,
        fill_colors = c("#000000", "#ffffff"),
        data_points = data_points,
        point_color = "#ff0000",
        metric_label = c("R2 = 0.1"),
        frame_directory_name = "prediction_frames",
        output_file_name = "prediction_test.gif",
        vec_palette = vec_palette,
        font_family = "sans"
      )

    testthat::expect_type(res, "list")
    testthat::expect_true(base::file.exists(res[["animation_path"]]))
    testthat::expect_true(isTRUE(res[["used_magick"]]))
  }
)

testthat::test_that(
  "save_prediction_animation() validates value_column",
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
      save_prediction_animation(
        data_frame = data_frame,
        value_column = "missing_column",
        subtitle_label = "Taxon",
        fill_label = "Probability",
        fill_limits = c(0, 1),
        vec_age_slices = c(2000),
        path_output = tempdir(),
        list_prediction_grid = base::list(
          x_lim = c(9, 12),
          y_lim = c(49, 52)
        ),
        data_world = data_world,
        grid_resolution = 1,
        time_step = 1000,
        fill_colors = c("#000000", "#ffffff"),
        frame_directory_name = "prediction_frames",
        output_file_name = "prediction_test.gif"
      ),
      regexp = "value_column"
    )
  }
)

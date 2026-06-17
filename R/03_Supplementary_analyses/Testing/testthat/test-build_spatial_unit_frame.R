testthat::test_that(
  "build_spatial_unit_frame() returns ggplot",
  {
    data_unit <-
      tibble::tibble(
        x_min = 10,
        x_max = 20,
        y_min = 40,
        y_max = 50
      )

    data_points <-
      tibble::tibble(
        coord_long = c(12, 18),
        coord_lat = c(42, 48)
      )

    data_world <-
      tibble::tibble(
        long = c(0, 30, 30, 0),
        lat = c(30, 30, 60, 60),
        group = c(1, 1, 1, 1)
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
      build_spatial_unit_frame(
        data_unit = data_unit,
        data_points = data_points,
        scale_label = "r005",
        data_world = data_world,
        x_limits = c(0, 30),
        y_limits = c(30, 60),
        buffer_degrees = 1,
        vec_palette = vec_palette,
        font_family = "sans"
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "build_spatial_unit_frame() validates buffer_degrees",
  {
    data_unit <-
      tibble::tibble(
        x_min = 10,
        x_max = 20,
        y_min = 40,
        y_max = 50
      )

    data_points <-
      tibble::tibble(
        coord_long = c(12, 18),
        coord_lat = c(42, 48)
      )

    data_world <-
      tibble::tibble(
        long = c(0, 30, 30, 0),
        lat = c(30, 30, 60, 60),
        group = c(1, 1, 1, 1)
      )

    testthat::expect_error(
      build_spatial_unit_frame(
        data_unit = data_unit,
        data_points = data_points,
        scale_label = "r005",
        data_world = data_world,
        x_limits = c(0, 30),
        y_limits = c(30, 60),
        buffer_degrees = -1
      ),
      regexp = "buffer_degrees"
    )
  }
)

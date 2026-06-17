testthat::test_that(
  "build_temporal_trajectory_frame() returns ggplot",
  {
    data_plot <-
      tibble::tibble(
        age = c(2000, 2000, 1000, 1000),
        component = c("abiotic", "biotic", "abiotic", "biotic"),
        component_percentage = c(40, 60, 55, 45)
      )

    data_modularity <-
      tibble::tibble(
        age = c(2000, 1000),
        modularity_q = c(0.3, 0.35)
      )

    vec_component_colours <-
      c(
        abiotic = "#1f77b4",
        biotic = "#ff7f0e"
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
      build_temporal_trajectory_frame(
        data_plot = data_plot,
        data_modularity = data_modularity,
        current_age = 1000,
        continent_label = "Europe",
        vec_component_colours = vec_component_colours,
        colour_modularity = "#ff00ff",
        vec_palette = vec_palette,
        font_family = "sans"
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "build_temporal_trajectory_frame() validates required columns",
  {
    data_plot <-
      tibble::tibble(
        age = c(2000, 1000),
        component = c("abiotic", "biotic")
      )

    data_modularity <-
      tibble::tibble(
        age = c(2000, 1000),
        modularity_q = c(0.3, 0.35)
      )

    testthat::expect_error(
      build_temporal_trajectory_frame(
        data_plot = data_plot,
        data_modularity = data_modularity,
        current_age = 1000,
        continent_label = "Europe",
        vec_component_colours = c(abiotic = "#111111"),
        colour_modularity = "#ff00ff"
      ),
      regexp = "data_plot"
    )
  }
)

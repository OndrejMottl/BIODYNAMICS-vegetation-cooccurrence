testthat::test_that(
  "save_temporal_trajectory_animation() writes GIF",
  {
    path_output <-
      base::file.path(
        tempdir(),
        "test_save_temporal_trajectory_animation"
      )

    data_temporal_components <-
      tibble::tibble(
        age = c(2000, 2000, 1000, 1000),
        component = c("abiotic", "biotic", "abiotic", "biotic"),
        component_percentage = c(40, 60, 55, 45)
      )

    data_temporal_modularity <-
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
      base::suppressWarnings(
        save_temporal_trajectory_animation(
          continent_label = "Europe",
          data_temporal_components = data_temporal_components,
          data_temporal_modularity = data_temporal_modularity,
          output_file_name = "temporal_test.gif",
          frame_directory_name = "temporal_frames",
          path_output = path_output,
          vec_component_colours = vec_component_colours,
          colour_modularity = "#ff00ff",
          vec_palette = vec_palette,
          font_family = "sans"
        )
      )

    testthat::expect_type(res, "list")
    testthat::expect_true(base::file.exists(res[["animation_path"]]))
    testthat::expect_true(isTRUE(res[["used_magick"]]))
  }
)

testthat::test_that(
  "save_temporal_trajectory_animation() validates output file name",
  {
    data_temporal_components <-
      tibble::tibble(
        age = c(2000, 2000),
        component = c("abiotic", "biotic"),
        component_percentage = c(40, 60)
      )

    data_temporal_modularity <-
      tibble::tibble(
        age = c(2000),
        modularity_q = c(0.3)
      )

    testthat::expect_error(
      save_temporal_trajectory_animation(
        continent_label = "Europe",
        data_temporal_components = data_temporal_components,
        data_temporal_modularity = data_temporal_modularity,
        output_file_name = "",
        frame_directory_name = "temporal_frames",
        path_output = tempdir(),
        vec_component_colours = c(abiotic = "#1f77b4"),
        colour_modularity = "#ff00ff"
      ),
      regexp = "output_file_name"
    )
  }
)

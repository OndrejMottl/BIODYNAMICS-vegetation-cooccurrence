testthat::test_that(
  "build_temporal_trajectory_legend() returns ggplot",
  {
    vec_required_components <-
      c("abiotic", "biotic")

    vec_component_labels <-
      c(
        abiotic = "Abiotic",
        biotic = "Biotic"
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
      build_temporal_trajectory_legend(
        vec_required_components = vec_required_components,
        vec_component_labels = vec_component_labels,
        vec_component_colours = vec_component_colours,
        colour_modularity = "#ff00ff",
        vec_palette = vec_palette,
        font_family = "sans"
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "build_temporal_trajectory_legend() validates label names",
  {
    testthat::expect_error(
      build_temporal_trajectory_legend(
        vec_required_components = c("abiotic", "biotic"),
        vec_component_labels = c(abiotic = "Abiotic"),
        vec_component_colours = c(
          abiotic = "#1f77b4",
          biotic = "#ff7f0e"
        ),
        colour_modularity = "#ff00ff"
      ),
      regexp = "vec_component_labels"
    )
  }
)

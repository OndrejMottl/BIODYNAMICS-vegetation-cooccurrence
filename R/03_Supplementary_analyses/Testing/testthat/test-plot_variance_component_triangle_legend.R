testthat::test_that(
  "plot_variance_component_triangle_legend() returns ggplot",
  {
    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    res_plot <-
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        plot_title = "Component mix"
      )

    testthat::expect_s3_class(res_plot, "ggplot")
  }
)

testthat::test_that(
  "plot_variance_component_triangle_legend() supports custom maximum",
  {
    vec_component_colours <-
      base::c(
        "Space" = "#33C9D5",
        "Climate" = "#E2C847",
        "Latent" = "#C792EA"
      )

    res_plot <-
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        vec_required_components = base::c(
          "Space",
          "Climate",
          "Latent"
        ),
        vec_component_labels = base::c(
          "SPACE",
          "CLIMATE",
          "LATENT"
        ),
        max_component_value = 10,
        component_step = 1
      )

    testthat::expect_s3_class(res_plot, "ggplot")
  }
)

testthat::test_that(
  "plot_variance_component_triangle_legend() colours labels",
  {
    vec_component_colours <-
      base::c(
        "Space" = "#33C9D5",
        "Climate" = "#E2C847",
        "Latent" = "#C792EA"
      )

    res_plot <-
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        vec_required_components = base::c(
          "Space",
          "Climate",
          "Latent"
        ),
        label_colour = vec_component_colours
      )

    list_layers <-
      purrr::chuck(res_plot, "layers")

    vec_text_colours <-
      list_layers[3:5] |>
      purrr::map_chr(
        .f = ~ purrr::chuck(.x, "aes_params", "colour")
      )

    testthat::expect_equal(
      base::unname(vec_text_colours),
      base::unname(vec_component_colours)
    )
  }
)

testthat::test_that(
  "plot_variance_component_triangle_legend() validates components",
  {
    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        vec_required_components = base::c("Abiotic", "Spatial")
      ),
      regexp = "exactly 3 components"
    )
  }
)

testthat::test_that(
  "plot_variance_component_triangle_legend() validates label colours",
  {
    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        label_colour = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3"
        )
      ),
      regexp = "length 1 or 3"
    )

    testthat::expect_error(
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours,
        label_colour = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3",
          "Other" = "#1B9E77"
        )
      ),
      regexp = "missing colours"
    )
  }
)

testthat::test_that(
  "plot_variance_component_triangle_legend() validates colours",
  {
    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3"
      )

    testthat::expect_error(
      plot_variance_component_triangle_legend(
        vec_component_colours = vec_component_colours
      ),
      regexp = "missing colours"
    )
  }
)

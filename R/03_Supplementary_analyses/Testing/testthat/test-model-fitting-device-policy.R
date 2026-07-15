testthat::test_that(
  "Model fitting uses the GPU backend",
  {
    config_default <-
      config::get(config = "default")

    config_cross_validation <-
      config_default |>
      purrr::chuck("model_fitting") |>
      purrr::chuck("cross_validation")

    testthat::expect_equal(
      config_cross_validation |>
        purrr::chuck("fit_device"),
      "gpu"
    )

    path_config <-
      here::here("config.yml")

    vec_device_settings <-
      readr::read_lines(path_config) |>
      stringr::str_trim() |>
      purrr::keep(
        ~ stringr::str_starts(.x, "fit_device:")
      )

    testthat::expect_equal(
      vec_device_settings,
      'fit_device: "gpu"'
    )

    path_model_fit <-
      here::here(
        "R",
        "Pipelines",
        "_pipes",
        "pipe_segment_model_fit.R"
      )

    text_model_fit <-
      readr::read_file(path_model_fit)

    testthat::expect_match(
      text_model_fit,
      'device = "gpu"',
      fixed = TRUE
    )
  }
)

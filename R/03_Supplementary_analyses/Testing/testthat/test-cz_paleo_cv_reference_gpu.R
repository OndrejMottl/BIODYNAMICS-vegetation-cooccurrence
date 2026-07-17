testthat::test_that(
  "CZ paleo GPU reference profile preserves the CPU store",
  {
    config_reference_gpu <-
      config::get(config = "project_cz_paleo_cv_reference_gpu")

    config_cross_validation <-
      config_reference_gpu |>
      purrr::chuck("model_fitting") |>
      purrr::chuck("cross_validation")

    testthat::expect_equal(
      config_reference_gpu |>
        purrr::chuck("target_store"),
      "Data/targets/cz_paleo_cv_reference_gpu"
    )

    testthat::expect_equal(
      config_cross_validation |>
        purrr::chuck("tier_id"),
      "cz_paleo_cv_reference_gpu"
    )

    testthat::expect_equal(
      config_cross_validation |>
        purrr::chuck("fit_device"),
      "gpu"
    )

    testthat::expect_equal(
      config_cross_validation |>
        purrr::chuck("assignment_repeats"),
      3L
    )

    testthat::expect_equal(
      config_reference_gpu |>
        purrr::chuck("model_fitting") |>
        purrr::chuck("n_iter"),
      500L
    )
  }
)

testthat::test_that(
  "CZ paleo GPU reference runner rebuilds only its core pipeline",
  {
    path_runner <-
      here::here(
        "R",
        "02_Main_analyses",
        "Run_CZ_paleo_cv_reference_gpu.R"
      )

    testthat::expect_true(fs::file_exists(path_runner))

    vec_runner_lines <-
      readr::read_lines(path_runner)

    text_runner <-
      stringr::str_c(vec_runner_lines, collapse = "\n")

    index_profile <-
      stringr::str_which(
        vec_runner_lines,
        'R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference_gpu"'
      )

    index_pipeline <-
      stringr::str_which(
        vec_runner_lines,
        'sel_script = "R/Pipelines/pipeline_paleo_core.R"'
      )

    testthat::expect_match(
      text_runner,
      'R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference_gpu"',
      fixed = TRUE
    )

    testthat::expect_match(
      text_runner,
      'sel_script = "R/Pipelines/pipeline_paleo_core.R"',
      fixed = TRUE
    )

    testthat::expect_match(
      text_runner,
      "fresh_run = TRUE",
      fixed = TRUE
    )

    testthat::expect_match(
      text_runner,
      "prebuild_interpolation = TRUE",
      fixed = TRUE
    )

    testthat::expect_length(index_profile, 1L)
    testthat::expect_length(index_pipeline, 1L)
    testthat::expect_lt(index_profile, index_pipeline)

    testthat::expect_equal(
      base::sum(stringr::str_detect(vec_runner_lines, "run_pipeline\\(")),
      1L
    )

    testthat::expect_false(
      stringr::str_detect(
        text_runner,
        "pipeline_paleo_resolution|pipeline_modern"
      )
    )

    testthat::expect_silent(base::parse(file = path_runner))
  }
)

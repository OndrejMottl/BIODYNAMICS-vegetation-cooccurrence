testthat::test_that(
  "CZ paleo CV reference profile is isolated and production-like",
  {
    config_reference <-
      config::get(config = "project_cz_paleo_cv_reference")

    config_cross_validation <-
      config_reference |>
      purrr::chuck("model_fitting") |>
      purrr::chuck("cross_validation")

    config_regularization <-
      config_cross_validation |>
      purrr::chuck("regularization")

    data_candidates <-
      make_sjsdm_regularization_candidates(
        alpha_cov = config_regularization |>
          purrr::chuck("alpha_cov"),
        alpha_coef = config_regularization |>
          purrr::chuck("alpha_coef"),
        alpha_spatial = config_regularization |>
          purrr::chuck("alpha_spatial"),
        lambda_cov = config_regularization |>
          purrr::chuck("lambda_cov"),
        lambda_coef = config_regularization |>
          purrr::chuck("lambda_coef"),
        lambda_spatial = config_regularization |>
          purrr::chuck("lambda_spatial")
      )

    testthat::expect_equal(
      config_reference |>
        purrr::chuck("target_store"),
      "Data/targets/cz_paleo_cv_reference"
    )

    testthat::expect_equal(
      config_cross_validation |>
        purrr::chuck("tier_id"),
      "cz_paleo_cv_reference"
    )

    testthat::expect_equal(
      config_cross_validation |>
        purrr::chuck("assignment_repeats"),
      3L
    )

    testthat::expect_equal(
      base::nrow(data_candidates),
      8L
    )

    testthat::expect_equal(
      config_reference |>
        purrr::chuck("vegvault_data") |>
        purrr::chuck("x_lim"),
      base::c(12, 18.9)
    )

    testthat::expect_equal(
      config_reference |>
        purrr::chuck("model_fitting") |>
        purrr::chuck("spatial_mode"),
      "spatiotemporal"
    )
  }
)

testthat::test_that(
  "CZ paleo CV reference runner rebuilds only the core pipeline",
  {
    path_runner <-
      here::here(
        "R",
        "03_Supplementary_analyses",
        "Validation",
        "Cross_validation",
        "Reference_runs",
        "run_cz_paleo_cv_reference.R"
      )

    testthat::expect_true(fs::file_exists(path_runner))

    vec_runner_lines <-
      readr::read_lines(path_runner)

    text_runner <-
      stringr::str_c(vec_runner_lines, collapse = "\n")

    index_profile <-
      stringr::str_which(
        vec_runner_lines,
        'R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference"'
      )

    index_pipeline <-
      stringr::str_which(
        vec_runner_lines,
        'sel_script = "R/Pipelines/pipeline_paleo_core.R"'
      )

    testthat::expect_match(
      text_runner,
      'R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference"',
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

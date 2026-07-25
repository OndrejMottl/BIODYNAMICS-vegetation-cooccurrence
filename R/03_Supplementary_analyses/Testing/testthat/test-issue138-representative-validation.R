testthat::test_that(
  "issue 138 spatial validation profiles select Europe genus",
  {
    vec_profiles <-
      base::c(
        "project_issue138_paleo_spatial_continental_europe_staged",
        "project_issue138_modern_spatial_continental_europe_staged"
      )

    purrr::walk(
      vec_profiles,
      function(profile_id) {
        list_config <-
          config::get(config = profile_id)

        testthat::expect_identical(
          list_config |>
            purrr::chuck(
              "model_fitting",
              "cross_validation",
              "tuning_strategy"
            ),
          "staged"
        )
        testthat::expect_identical(
          list_config |>
            purrr::chuck(
              "model_fitting",
              "cross_validation",
              "tuning_context",
              "resolution_ids"
            ),
          "genus"
        )
        testthat::expect_identical(
          list_config |>
            purrr::chuck(
              "data_processing",
              "n_interpolation_workers"
            ),
          4L
        )
      }
    )
  }
)

testthat::test_that(
  "issue 138 temporal profiles select one staged slice",
  {
    vec_profiles <-
      base::c(
        "project_paleo_temporal_issue138_europe_staged",
        "project_paleo_temporal_issue138_america_staged",
        "project_paleo_temporal_issue138_asia_staged"
      )
    vec_ages <-
      base::c(16000, 19000, 6500)

    purrr::walk2(
      vec_profiles,
      vec_ages,
      function(profile_id, expected_age) {
        list_config <-
          config::get(config = profile_id)

        testthat::expect_identical(
          list_config |>
            purrr::chuck("vegvault_data", "age_lim"),
          base::rep(expected_age, 2L)
        )
        testthat::expect_identical(
          list_config |>
            purrr::chuck(
              "model_fitting",
              "cross_validation",
              "tuning_strategy"
            ),
          "staged"
        )
        testthat::expect_identical(
          list_config |>
            purrr::chuck(
              "data_processing",
              "n_interpolation_workers"
            ),
          4L
        )
      }
    )
  }
)

testthat::test_that(
  "issue 138 sampler tolerates isolated Windows query failures",
  {
    text_harness <-
      readr::read_file(
        here::here(
          "R/03_Supplementary_analyses/Testing",
          "Run_issue138_cv_benchmark.ps1"
        )
      )

    testthat::expect_match(
      text_harness,
      "$maximumConsecutiveSamplingFailures = 30",
      fixed = TRUE
    )
    testthat::expect_match(
      text_harness,
      "$consecutiveSamplingFailures += 1",
      fixed = TRUE
    )
    testthat::expect_match(
      text_harness,
      "$consecutiveSamplingFailures = 0",
      fixed = TRUE
    )
    testthat::expect_match(
      text_harness,
      "Stop-Process -Id $lastKnownProcessIds",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "tier tuning applies the configured resolution context",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE =
        "project_issue138_paleo_spatial_continental_europe_staged"
    )

    environment_pipeline <-
      base::new.env(parent = base::globalenv())

    base::source(
      here::here("R/Pipelines/pipeline_sjsdm_tier_tuning.R"),
      local = environment_pipeline
    )

    testthat::expect_identical(
      environment_pipeline$list_tuning_context[["resolution_ids"]],
      "genus"
    )
  }
)

testthat::test_that(
  "issue 138 representative runners use the shared validation helper",
  {
    vec_runner_paths <-
      here::here(
        "R/02_Main_analyses",
        base::c(
          "Run_issue138_paleo_continental_europe_staged.R",
          "Run_issue138_modern_continental_europe_staged.R",
          "Run_issue138_temporal_europe_staged.R",
          "Run_issue138_temporal_america_staged.R",
          "Run_issue138_temporal_asia_staged.R"
        )
      )

    purrr::walk(
      vec_runner_paths,
      function(path_runner) {
        testthat::expect_true(fs::file_exists(path_runner))
        testthat::expect_match(
          readr::read_file(path_runner),
          "run_issue138_representative_validation(",
          fixed = TRUE
        )
      }
    )
  }
)

testthat::test_that(
  "issue 143 continental validation inherits the shared MEM strategy",
  {
    profile_id <-
      "project_issue143_modern_spatial_continental_europe_shared_mem"

    list_config <-
      config::get(config = profile_id)

    testthat::expect_identical(
      list_config |>
        purrr::chuck("model_fitting", "spatial_mev", "strategy"),
      "auto"
    )
    testthat::expect_identical(
      list_config |>
        purrr::chuck(
          "model_fitting",
          "spatial_mev",
          "exact_max_locations"
        ),
      1999L
    )
    testthat::expect_identical(
      list_config |>
        purrr::chuck(
          "model_fitting",
          "cross_validation",
          "tuning_strategy"
        ),
      "staged"
    )
    testthat::expect_identical(
      list_config[["target_store"]],
      "Data/targets/issue143_validation/modern_continental_europe"
    )

    path_runner <-
      here::here(
        "R/02_Main_analyses",
        "Run_issue143_modern_continental_europe_shared_mem.R"
      )

    testthat::expect_true(fs::file_exists(path_runner))
    testthat::expect_match(
      readr::read_file(path_runner),
      "run_issue138_representative_validation(",
      fixed = TRUE
    )
    testthat::expect_false(
      stringr::str_detect(
        readr::read_file(path_runner),
        stringr::fixed("model_anova_genus")
      )
    )
  }
)

testthat::test_that(
  "model fitting configs propagate the shared MEM strategy to folds",
  {
    text_shared <-
      readr::read_file(
        here::here(
          "R/Pipelines/_pipes/pipe_segment_config_model.R"
        )
      )
    text_resolution <-
      readr::read_file(
        here::here(
          paste0(
            "R/Pipelines/_pipes/",
            "pipe_segment_config_model_by_resolution.R"
          )
        )
      )

    testthat::expect_match(
      text_shared,
      'name = "config_spatial_mev"',
      fixed = TRUE
    )
    testthat::expect_match(
      text_shared,
      "spatial_mev = config_spatial_mev",
      fixed = TRUE
    )
    testthat::expect_match(
      text_resolution,
      "spatial_mev = get_active_config(",
      fixed = TRUE
    )
    testthat::expect_match(
      text_resolution,
      'value = c("model_fitting", "spatial_mev")',
      fixed = TRUE
    )
  }
)

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
      }
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

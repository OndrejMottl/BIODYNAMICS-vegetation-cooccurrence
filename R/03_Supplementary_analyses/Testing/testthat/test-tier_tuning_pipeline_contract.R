testthat::test_that(
  "tier tuning refreshes summaries read from external stores",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_paleo_spatial_continental"
    )

    environment_pipeline <-
      base::new.env(parent = base::globalenv())

    list_pipeline <-
      base::source(
        here::here("R/Pipelines/pipeline_sjsdm_tier_tuning.R"),
        local = environment_pipeline
      )["value"][[1L]]

    target_summary <-
      list_pipeline |>
      purrr::keep(
        ~ base::identical(
          base::as.list(.x[["settings"]])["name"][[1L]],
          "data_sjsdm_tier_tuning_summaries"
        )
      )

    testthat::expect_length(target_summary, 1L)
    testthat::expect_identical(
      base::as.list(target_summary[[1L]][["cue"]])["mode"][[1L]],
      "always"
    )
  }
)

testthat::test_that(
  "tier tuning declares explicit staged round boundaries",
  {
    text_pipeline <-
      readr::read_file(
        here::here("R/Pipelines/pipeline_sjsdm_tier_tuning.R")
      )

    vec_required_text <-
      base::c(
        "build_sjsdm_tier_survivor_artifacts(",
        "data_sjsdm_tier_survivor_decisions_round_1",
        "data_sjsdm_tier_survivor_decisions_round_2",
        "data_sjsdm_tier_survivor_decisions_round_3",
        "list_sjsdm_tier_tuning_artifact",
        "target_store = load_active_config_value(\"target_store\")",
        "deployment = \"main\""
      )

    purrr::walk(
      vec_required_text,
      .f = ~ testthat::expect_match(
        text_pipeline,
        .x,
        fixed = TRUE
      )
    )
  }
)

testthat::test_that(
  "tier artifact creation time changes only with source evidence",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_paleo_spatial_continental"
    )

    environment_pipeline <-
      base::new.env(parent = base::globalenv())

    list_pipeline <-
      base::source(
        here::here("R/Pipelines/pipeline_sjsdm_tier_tuning.R"),
        local = environment_pipeline
      )["value"][[1L]]

    target_created_at <-
      list_pipeline |>
      purrr::keep(
        ~ base::identical(
          base::as.list(.x[["settings"]])["name"][[1L]],
          "sjsdm_tier_artifact_created_at"
        )
      )

    testthat::expect_length(target_created_at, 1L)
    testthat::expect_identical(
      base::as.list(target_created_at[[1L]][["cue"]])[
        "mode"
      ][[1L]],
      "thorough"
    )
    testthat::expect_match(
      target_created_at[[1L]][["command"]][["string"]],
      "data_sjsdm_tier_tuning_summaries",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "active CV pipelines contain no legacy reader fallback",
  {
    vec_paths <-
      base::c(
        here::here(
          "R/Pipelines/pipeline_cz_paleo_cv_component_reference.R"
        ),
        here::here(
          "R/Pipelines/",
          "pipeline_cz_paleo_cv_regularization_reference.R"
        ),
        here::here(
          "R/Pipelines/_pipes/",
          "pipe_segment_model_cross_validation_execution.R"
        )
      )

    vec_text <-
      purrr::map_chr(vec_paths, readr::read_file)

    testthat::expect_false(
      stringr::str_detect(
        vec_text,
        "v1_target_name|data_sjsdm_tier_regularization_artifacts"
      ) |>
        base::any()
    )
  }
)

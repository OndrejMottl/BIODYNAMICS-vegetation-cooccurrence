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

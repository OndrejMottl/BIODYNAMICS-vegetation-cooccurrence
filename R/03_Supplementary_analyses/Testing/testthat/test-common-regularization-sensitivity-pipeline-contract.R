testthat::test_that(
  "common sensitivity excludes expected-infeasible unit stores",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_paleo_spatial_local"
    )

    environment_pipeline <-
      base::new.env(parent = base::globalenv())

    base::source(
      here::here(
        "R/Pipelines/",
        "pipeline_sjsdm_common_regularization_sensitivity.R"
      ),
      local = environment_pipeline
    )

    data_context <-
      environment_pipeline[["data_spatial_profile_context"]]
    vec_local_scale_ids <-
      data_context |>
      dplyr::filter(
        .data[["profile_id"]] == "project_paleo_spatial_local"
      ) |>
      dplyr::pull("eligible_scale_ids") |>
      purrr::pluck(1L)

    testthat::expect_length(vec_local_scale_ids, 65L)
    testthat::expect_contains(
      vec_local_scale_ids,
      "am_r011_l002"
    )
    testthat::expect_false(
      "am_r001_l001" %in% vec_local_scale_ids
    )
  }
)

testthat::test_that(
  "common sensitivity loads only inventory-eligible stores",
  {
    text_pipeline <-
      readr::read_file(
        here::here(
          "R/Pipelines/",
          "pipeline_sjsdm_common_regularization_sensitivity.R"
        )
      )

    testthat::expect_match(
      text_pipeline,
      '.x[["eligible_scale_ids"]][[1L]]',
      fixed = TRUE
    )
    testthat::expect_false(
      stringr::str_detect(
        text_pipeline,
        "fs::dir_ls\\("
      )
    )
  }
)

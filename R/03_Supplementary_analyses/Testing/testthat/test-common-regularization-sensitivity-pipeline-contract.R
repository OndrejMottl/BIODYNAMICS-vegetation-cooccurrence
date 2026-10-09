testthat::test_that(
  "common sensitivity excludes expected-infeasible unit stores",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_paleo_spatial_local"
    )
    data_fixture <-
      tidyr::crossing(
        tibble::tibble(
          tier_id = base::c("continental", "regional", "local",
            "local", "local"),
          scale_id = base::c("europe", "eu_r005", "eu_r005_l014",
            "am_r011_l002", "am_r001_l001")
        ),
        resolution_id = base::c("genus", "family", "functional_type")
      ) |>
      dplyr::mutate(
        analysis_id = "paleo_spatial",
        preparation_status = dplyr::if_else(
          .data[["scale_id"]] == "am_r001_l001",
          "expected_infeasible", "prepared"
        ),
        preparation_reason_code = dplyr::if_else(
          .data[["preparation_status"]] == "expected_infeasible",
          "insufficient_samples", NA_character_
        )
      )
    function_read_csv <-
      readr::read_csv
    testthat::local_mocked_bindings(
      read_csv = function(file, ...) {
        if (
          base::basename(file) == "calibration_unit_inventory.csv"
        ) {
          return(data_fixture)
        }
        return(function_read_csv(file = file, ...))
      },
      .package = "readr"
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

    testthat::expect_setequal(
      vec_local_scale_ids, base::c("eu_r005_l014", "am_r011_l002")
    )
    testthat::expect_contains(
      vec_local_scale_ids,
      "am_r011_l002"
    )
    testthat::expect_false(
      "am_r001_l001" %in% vec_local_scale_ids
    )
    data_fixture[["preparation_status"]][
      data_fixture[["scale_id"]] == "am_r011_l002"
    ] <-
      "pipeline_error"
    testthat::expect_error(
      base::source(
        file = here::here(
          "R/Pipelines/pipeline_sjsdm_common_regularization_sensitivity.R"
        ),
        local = base::new.env(parent = base::globalenv())
      ),
      "Preparation evidence is missing or unresolved"
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

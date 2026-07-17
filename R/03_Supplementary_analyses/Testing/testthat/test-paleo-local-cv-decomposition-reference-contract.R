testthat::test_that(
  "paleo local decomposition reference has a matched-fold GPU contract",
  {
    config_reference <-
      config::get(
        config = "project_paleo_local_cv_decomposition_reference_gpu"
      )

    testthat::expect_equal(
      config_reference[["target_store"]],
      "Data/targets/paleo_local_cv_decomposition_reference_gpu"
    )
    testthat::expect_equal(
      purrr::chuck(
        config_reference,
        "model_fitting",
        "cross_validation",
        "fit_device"
      ),
      "gpu"
    )

    path_pipeline <-
      here::here(
        "R/Pipelines/pipeline_paleo_local_cv_decomposition_reference.R"
      )

    text_pipeline <-
      readr::read_file(path_pipeline)

    testthat::expect_match(
      text_pipeline,
      "paleo_local_cv_scientific_reference_gpu/",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "pipeline_paleo_local_cv_scientific_reference",
      fixed = TRUE
    )

    list_expected_variants <-
      base::list(
        no_abiotic = "spatial_only",
        no_spatial = "abiotic_only",
        no_associations = "abiotic_spatial_no_associations"
      )

    purrr::iwalk(
      .x = list_expected_variants,
      .f = ~ {
        testthat::expect_match(
          text_pipeline,
          stringr::str_glue(
            "list_scientific_reference_{.y}_fold_predictions"
          ),
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipeline,
          stringr::str_glue('predictor_structure = "{.x}"'),
          fixed = TRUE
        )
      }
    )

    testthat::expect_match(
      text_pipeline,
      "data_scientific_reference_decomposition_fold_metrics",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      '.data[["prediction_source"]] == "model"',
      fixed = TRUE
    )

    path_runner <-
      here::here(
        "R/02_Main_analyses/Run_paleo_local_cv_decomposition_reference_gpu.R"
      )

    text_runner <-
      readr::read_file(path_runner)

    testthat::expect_match(
      text_runner,
      "project_paleo_local_cv_decomposition_reference_gpu",
      fixed = TRUE
    )
    testthat::expect_match(
      text_runner,
      "fresh_run = TRUE",
      fixed = TRUE
    )
  }
)

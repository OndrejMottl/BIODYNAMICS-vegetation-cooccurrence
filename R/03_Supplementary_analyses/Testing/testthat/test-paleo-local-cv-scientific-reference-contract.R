testthat::test_that(
  "paleo local scientific reference has an isolated GPU contract",
  {
    config_reference <-
      config::get(
        config = "project_paleo_local_cv_scientific_reference_gpu"
      )

    testthat::expect_equal(
      config_reference[["target_store"]],
      "Data/targets/paleo_local_cv_scientific_reference_gpu"
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
    testthat::expect_equal(
      purrr::chuck(
        config_reference,
        "model_fitting",
        "cross_validation",
        "assignment_repeats"
      ),
      3L
    )

    path_pipeline <-
      here::here(
        "R/Pipelines/pipeline_paleo_local_cv_scientific_reference.R"
      )
    text_pipeline <-
      readr::read_file(path_pipeline)

    testthat::expect_match(
      text_pipeline,
      "paleo_spatial_local/eu_r005_l010/",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "data_scientific_reference_assignments",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "data_scientific_reference_fold_metrics",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "list_scientific_reference_repeat_distributions",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "fit_device",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "lambda_cov = base::c(0.1)",
      fixed = TRUE
    )

    path_runner <-
      here::here(
        "R/02_Main_analyses/Run_paleo_local_cv_scientific_reference_gpu.R"
      )
    text_runner <-
      readr::read_file(path_runner)

    testthat::expect_match(
      text_runner,
      "project_paleo_local_cv_scientific_reference_gpu",
      fixed = TRUE
    )
    testthat::expect_match(
      text_runner,
      "fresh_run = TRUE",
      fixed = TRUE
    )
  }
)

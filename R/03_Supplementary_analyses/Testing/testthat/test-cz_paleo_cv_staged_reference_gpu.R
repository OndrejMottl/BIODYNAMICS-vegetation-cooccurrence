testthat::test_that(
  "CZ staged GPU reference is paired with exhaustive tuning",
  {
    config_exhaustive <-
      config::get(config = "project_cz_paleo_cv_reference_gpu")

    config_staged <-
      config::get(config = "project_cz_paleo_cv_staged_reference_gpu")

    cross_validation_exhaustive <-
      config_exhaustive |>
      purrr::chuck("model_fitting", "cross_validation")

    cross_validation_staged <-
      config_staged |>
      purrr::chuck("model_fitting", "cross_validation")

    testthat::expect_identical(
      config_staged[["target_store"]],
      "Data/targets/cz_paleo_cv_staged_reference_gpu"
    )
    testthat::expect_identical(
      cross_validation_exhaustive[["tuning_strategy"]],
      "exhaustive"
    )
    testthat::expect_identical(
      cross_validation_staged[["tuning_strategy"]],
      "staged"
    )
    testthat::expect_identical(
      cross_validation_staged[["tier_id"]],
      cross_validation_exhaustive[["tier_id"]]
    )
    testthat::expect_identical(
      cross_validation_staged[["assignment_seed"]],
      cross_validation_exhaustive[["assignment_seed"]]
    )
    testthat::expect_identical(
      cross_validation_staged[["fit_seed"]],
      cross_validation_exhaustive[["fit_seed"]]
    )
    testthat::expect_identical(
      cross_validation_staged[["regularization"]],
      cross_validation_exhaustive[["regularization"]]
    )
    testthat::expect_identical(
      cross_validation_staged[["staged_search"]][["repeat_order"]],
      base::c(1L, 2L, 3L)
    )
    testthat::expect_identical(
      cross_validation_staged[["staged_search"]][["survivor_counts"]],
      base::c(4L, 2L)
    )
    testthat::expect_identical(
      config_staged[["model_fitting"]][["model_tuning_id"]],
      "paleo_core"
    )
  }
)

testthat::test_that(
  "CZ staged GPU runner uses shared round orchestration",
  {
    path_runner <-
      here::here(
        "R/02_Main_analyses/Run_CZ_paleo_cv_staged_reference_gpu.R"
      )

    testthat::expect_true(fs::file_exists(path_runner))

    text_runner <-
      readr::read_file(path_runner)

    testthat::expect_match(
      text_runner,
      "project_cz_paleo_cv_staged_reference_gpu",
      fixed = TRUE
    )
    testthat::expect_match(
      text_runner,
      "run_sjsdm_tuning_sequence(",
      fixed = TRUE
    )
    testthat::expect_match(
      text_runner,
      "fresh_run = TRUE",
      fixed = TRUE
    )
    testthat::expect_match(
      text_runner,
      'unit_pipeline = "R/Pipelines/pipeline_paleo_core.R"',
      fixed = TRUE
    )
  }
)

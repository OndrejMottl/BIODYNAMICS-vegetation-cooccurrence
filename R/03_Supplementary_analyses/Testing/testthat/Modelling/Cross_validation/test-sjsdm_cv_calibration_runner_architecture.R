testthat::test_that(
  "calibration has one master and three recovery components",
  {
    path_stage <-
      here::here("R/02_Main_analyses/02_Model_calibration")
    path_components <-
      base::file.path(path_stage, "_components")
    vec_expected_components <-
      base::c(
        "01_build_sjsdm_cv_calibration_inventory.R",
        "02_run_one_sjsdm_cv_fit_budget_calibration.R",
        "03_publish_sjsdm_cv_fit_budgets.R"
      )

    testthat::expect_true(
      base::file.exists(
        base::file.path(path_stage, "01_run_model_calibration.R")
      )
    )
    testthat::expect_true(
      base::all(
        base::file.exists(
          base::file.path(path_components, vec_expected_components)
        )
      )
    )
    testthat::expect_false(
      base::dir.exists(
        here::here("R/02_Main_analyses/00_Model_calibration")
      )
    )
  }
)

testthat::test_that(
  "calibration master enumerates registered representatives",
  {
    text_master <-
      readr::read_file(
        here::here(
          "R/02_Main_analyses/02_Model_calibration/",
          "01_run_model_calibration.R"
        )
      )

    testthat::expect_match(
      text_master,
      "calibration_representatives.csv",
      fixed = TRUE
    )
    testthat::expect_match(
      text_master,
      "continue_on_error = TRUE",
      fixed = TRUE
    )
    testthat::expect_match(
      text_master,
      "03_publish_sjsdm_cv_fit_budgets.R",
      fixed = TRUE
    )
    testthat::expect_match(
      text_master,
      "Check_configuration.R",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "calibration recovery reconstructs disposable prepared inputs",
  {
    text_component <-
      readr::read_file(
        here::here(
          "R/02_Main_analyses/02_Model_calibration/_components/",
          "02_run_one_sjsdm_cv_fit_budget_calibration.R"
        )
      )

    testthat::expect_match(
      text_component,
      "build_sjsdm_regularization_candidates(",
      fixed = TRUE
    )
    testthat::expect_match(
      text_component,
      "build_jsdm_environment_formula(",
      fixed = TRUE
    )
    testthat::expect_false(
      stringr::str_detect(
        text_component,
        paste0(
          "targets::tar_read_raw\\(\\s*name = stringr::str_c",
          '\\(\\s*"data_sjsdm_regularization_candidates"'
        )
      )
    )
  }
)

testthat::test_that(
  "temporal calibration uses its shared fitting configuration target",
  {
    text_component <-
      readr::read_file(
        here::here(
          "R/02_Main_analyses/02_Model_calibration/_components/",
          "02_run_one_sjsdm_cv_fit_budget_calibration.R"
        )
      )

    testthat::expect_match(
      text_component,
      'target_model_fitting_config <-',
      fixed = TRUE
    )
    testthat::expect_match(
      text_component,
      '} else {\n    "config_model_fitting"',
      fixed = TRUE
    )
    testthat::expect_match(
      text_component,
      "name = target_model_fitting_config",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "calibration migrates accepted results from stricter contracts",
  {
    text_component <-
      readr::read_file(
        here::here(
          "R/02_Main_analyses/02_Model_calibration/_components/",
          "02_run_one_sjsdm_cv_fit_budget_calibration.R"
        )
      )
    text_publication <-
      readr::read_file(
        here::here(
          "R/02_Main_analyses/02_Model_calibration/_components/",
          "03_publish_sjsdm_cv_fit_budgets.R"
        )
      )

    testthat::expect_match(
      text_component,
      "sjsdm_cv_adaptive_calibration_v3",
      fixed = TRUE
    )
    testthat::expect_match(
      text_component,
      "reused_stricter_v2_result",
      fixed = TRUE
    )
    testthat::expect_match(
      text_component,
      "reused_stricter_v3_policy_result",
      fixed = TRUE
    )
    testthat::expect_match(
      text_publication,
      "sjsdm_cv_adaptive_calibration_v3",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "legacy audit and invalidation are one-time workflows",
  {
    path_migration <-
      here::here(
        "R/03_Supplementary_analyses/One_time/Cross_validation/",
        "Fit_budget_migration"
      )
    testthat::expect_true(
      base::all(
        base::file.exists(
          base::file.path(
            path_migration,
            base::c(
              "audit_completed_sjsdm_continental_results.R",
              "build_sjsdm_cv_invalidation_manifest.R"
            )
          )
        )
      )
    )
  }
)

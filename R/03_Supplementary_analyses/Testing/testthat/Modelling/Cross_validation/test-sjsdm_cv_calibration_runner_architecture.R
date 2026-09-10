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

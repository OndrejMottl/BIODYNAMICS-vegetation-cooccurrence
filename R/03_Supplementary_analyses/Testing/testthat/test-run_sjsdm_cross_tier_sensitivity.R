make_common_sensitivity_config <- function(
    profile_id,
    enabled = TRUE) {
  base::list(
    target_store = base::file.path("stores", profile_id),
    model_fitting = base::list(
      cross_validation = base::list(
        tier_id = profile_id,
        common_regularization_sensitivity = base::list(
          enabled = enabled,
          representative_scale_id = stringr::str_c(profile_id, "_unit")
        )
      )
    )
  )
}

testthat::test_that(
  "common sensitivity is skipped with actionable missing-store status",
  {
    environment_run <-
      base::new.env(parent = base::emptyenv())

    environment_run[["called"]] <-
      FALSE

    config_load_function <- function(config_id, file) {
      testthat::expect_identical(file, "config.yml")
      make_common_sensitivity_config(config_id)
    }

    dir_exists_function <- function(path) {
      !stringr::str_detect(path, "profile_b")
    }

    run_pipeline_function <- function(sel_script) {
      environment_run[["called"]] <-
        TRUE

      base::invisible(sel_script)
    }

    result <-
      testthat::expect_message(
        run_sjsdm_cross_tier_sensitivity(
          profile_ids = base::c("profile_a", "profile_b"),
          pipeline_name = "pipeline_resolution",
          config_file = "config.yml",
          project_root = "project_root",
          config_load_function = config_load_function,
          dir_exists_function = dir_exists_function,
          run_pipeline_function = run_pipeline_function
        ),
        "Skipping.*profile_b_unit"
      )

    testthat::expect_false(environment_run[["called"]])
    testthat::expect_named(
      result,
      base::c(
        "profile_id",
        "tier_id",
        "scale_id",
        "store_path",
        "store_status",
        "sensitivity_status"
      )
    )
    testthat::expect_identical(
      result[["store_status"]],
      base::c("ready", "missing")
    )
    testthat::expect_identical(
      result[["sensitivity_status"]],
      base::rep("skipped_missing_store", 2L)
    )
  }
)

testthat::test_that(
  "common sensitivity runs only when every representative store is ready",
  {
    environment_run <-
      base::new.env(parent = base::emptyenv())

    environment_run[["scripts"]] <-
      base::character()

    result <-
      run_sjsdm_cross_tier_sensitivity(
        profile_ids = base::c("profile_a", "profile_b"),
        pipeline_name = "pipeline_resolution",
        sensitivity_script = "sensitivity.R",
        config_file = "config.yml",
        project_root = "project_root",
        config_load_function = function(config_id, file) {
          make_common_sensitivity_config(
            profile_id = config_id,
            enabled = config_id == "profile_a"
          )
        },
        dir_exists_function = function(path) {
          base::rep(TRUE, base::length(path))
        },
        run_pipeline_function = function(sel_script) {
          environment_run[["scripts"]] <-
            base::c(environment_run[["scripts"]], sel_script)

          base::invisible(NULL)
        }
      )

    testthat::expect_identical(
      environment_run[["scripts"]],
      "sensitivity.R"
    )
    testthat::expect_identical(
      result[["store_status"]],
      base::c("ready", "disabled")
    )
    testthat::expect_identical(
      result[["sensitivity_status"]],
      base::c("completed", "skipped_disabled")
    )
  }
)

testthat::test_that(
  "common sensitivity is a no-op when every profile is disabled",
  {
    environment_run <-
      base::new.env(parent = base::emptyenv())

    environment_run[["called"]] <-
      FALSE

    result <-
      testthat::expect_message(
        run_sjsdm_cross_tier_sensitivity(
          profile_ids = base::c("profile_a", "profile_b"),
          pipeline_name = "pipeline_resolution",
          config_file = "config.yml",
          project_root = "project_root",
          config_load_function = function(config_id, file) {
            make_common_sensitivity_config(
              profile_id = config_id,
              enabled = FALSE
            )
          },
          dir_exists_function = function(path) {
            base::stop("Disabled stores must not be checked.")
          },
          run_pipeline_function = function(sel_script) {
            environment_run[["called"]] <-
              TRUE
          }
        ),
        "all configured profiles are disabled"
      )

    testthat::expect_false(environment_run[["called"]])
    testthat::expect_identical(
      result[["store_status"]],
      base::rep("disabled", 2L)
    )
    testthat::expect_identical(
      result[["sensitivity_status"]],
      base::rep("skipped_disabled", 2L)
    )
  }
)

testthat::test_that(
  "local runners publish the common-sensitivity readiness status",
  {
    runner_paths <-
      here::here(
        base::c(
          "R/02_Main_analyses/01_Spatial/01_Paleo",
          "R/02_Main_analyses/01_Spatial/02_Contemporary"
        ),
        base::c(
          "03_Run_spatial_local.R",
          "03_Run_modern_local.R"
        )
      )

    runner_text <-
      runner_paths |>
      purrr::map_chr(
        ~ base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")
      )

    testthat::expect_true(
      base::all(
        stringr::str_count(
          runner_text,
          "run_sjsdm_cross_tier_sensitivity\\("
        ) == 1L
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          runner_text,
          "data_common_sensitivity_status <-"
        )
      )
    )
  }
)

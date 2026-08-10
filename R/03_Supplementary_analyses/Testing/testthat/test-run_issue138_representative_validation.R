testthat::test_that(
  "run_issue138_representative_validation() controls shared resume",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())

    sequence_function <-
      function(...) {
        environment_calls[["sequence"]] <-
          base::list(...)
        environment_calls[["active_sequence"]] <-
          base::Sys.getenv("R_CONFIG_ACTIVE")
      }

    pipeline_function <-
      function(...) {
        environment_calls[["pipeline"]] <-
          base::list(...)
        environment_calls[["active_pipeline"]] <-
          base::Sys.getenv("R_CONFIG_ACTIVE")
      }

    res <-
      run_issue138_representative_validation(
        active_config =
          "project_issue138_paleo_spatial_continental_europe_staged",
        unit_pipeline =
          "R/Pipelines/pipeline_paleo_spatial_resolution.R",
        tuning_target_names = "data_sjsdm_tuning_summary_genus",
        final_target_names = base::c(
          "list_jsdm_variance_partition_genus",
          "model_evaluation_cross_validated_genus"
        ),
        store_suffix = "europe",
        prebuild_interpolation = TRUE,
        fresh_run = FALSE,
        run_sequence_function = sequence_function,
        run_pipeline_function = pipeline_function
      )

    testthat::expect_null(res)
    testthat::expect_identical(
      environment_calls[["sequence"]][["fresh_run"]],
      FALSE
    )
    testthat::expect_identical(
      environment_calls[["sequence"]][["tuning_strategy"]],
      "staged"
    )
    testthat::expect_identical(
      environment_calls[["sequence"]][["n_rounds"]],
      3L
    )
    testthat::expect_identical(
      environment_calls[["sequence"]][["unit_store_suffixes"]],
      "europe"
    )
    testthat::expect_identical(
      environment_calls[["sequence"]][["vec_allowed_profile_roles"]],
      "one_time"
    )
    testthat::expect_identical(
      environment_calls[["sequence"]][["vec_allowed_profile_statuses"]],
      "frozen"
    )
    testthat::expect_identical(
      environment_calls[["pipeline"]][["target_names"]],
      base::c(
        "list_jsdm_variance_partition_genus",
        "model_evaluation_cross_validated_genus"
      )
    )
    testthat::expect_identical(
      environment_calls[["pipeline"]][["fresh_run"]],
      FALSE
    )
    testthat::expect_identical(
      environment_calls[["pipeline"]][["vec_allowed_profile_roles"]],
      "one_time"
    )
    testthat::expect_identical(
      environment_calls[["pipeline"]][["vec_allowed_profile_statuses"]],
      "frozen"
    )
    testthat::expect_identical(
      environment_calls[["active_sequence"]],
      environment_calls[["active_pipeline"]]
    )
  }
)

testthat::test_that(
  "run_issue138_representative_validation() rejects malformed inputs",
  {
    testthat::expect_error(
      run_issue138_representative_validation(
        active_config = "",
        unit_pipeline = "pipeline.R",
        tuning_target_names = "summary",
        final_target_names = "model"
      ),
      "active_config"
    )
    testthat::expect_error(
      run_issue138_representative_validation(
        active_config = "profile",
        unit_pipeline = "pipeline.R",
        tuning_target_names = base::character(),
        final_target_names = "model"
      ),
      "tuning_target_names"
    )
    testthat::expect_error(
      run_issue138_representative_validation(
        active_config = "profile",
        unit_pipeline = "pipeline.R",
        tuning_target_names = "summary",
        final_target_names = "model",
        fresh_run = NA
      ),
      "fresh_run"
    )
  }
)

testthat::test_that(
  "CZ component reference exposes isolated GPU evidence targets",
  {
    path_pipeline <-
      here::here(
        "R/Pipelines/pipeline_cz_paleo_cv_component_reference.R"
      )

    text_pipeline <-
      readr::read_file(path_pipeline)

    vec_structures <-
      base::c("intercept_only", "abiotic_only", "spatial_only")

    purrr::walk(
      vec_structures,
      ~ {
        testthat::expect_match(
          text_pipeline,
          stringr::str_glue(
            "list_sjsdm_{.x}_fold_predictions"
          ),
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipeline,
          stringr::str_glue(
            "data_sjsdm_{.x}_fold_metrics"
          ),
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipeline,
          stringr::str_glue(
            "list_sjsdm_{.x}_repeat_distributions"
          ),
          fixed = TRUE
        )
      }
    )

    testthat::expect_match(
      text_pipeline,
      "cz_paleo_cv_reference_gpu/pipeline_paleo_core",
      fixed = TRUE
    )
    testthat::expect_equal(
      stringr::str_count(
        text_pipeline,
        stringr::fixed("cue = targets::tar_cue(mode = \"always\")")
      ),
      12L
    )

    path_runner <-
      here::here(
        "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_component_reference_gpu.R"
      )

    text_runner <-
      readr::read_file(path_runner)

    testthat::expect_match(
      text_runner,
      "project_cz_paleo_cv_component_reference_gpu",
      fixed = TRUE
    )
    testthat::expect_match(text_runner, "fresh_run = TRUE", fixed = TRUE)
  }
)

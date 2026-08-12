testthat::test_that(
  "shared CV pipes reuse tuning predictions for selected OOF output",
  {
    vec_pipe_paths <-
      here::here(
        base::paste0(
          "R/Pipelines/_pipes/",
          "pipe_segment_model_cross_validation_execution.R"
        )
      )

    purrr::walk(
      vec_pipe_paths,
      .f = ~ {
        text_pipe <-
          readr::read_file(.x)

        testthat::expect_match(
          text_pipe,
          "prepare_sjsdm_tuning_folds(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "build_sjsdm_tuning_work_items(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "validate_sjsdm_tuning_repeat_coverage(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "load_sjsdm_available_tier_decisions(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "build_sjsdm_cumulative_tuning_work_items(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "base::Sys.getenv(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "SJSMD_TUNING_MAX_ROUND",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          'name = "data_sjsdm_all_tuning_work_items"',
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "run_sjsdm_tuning_work_item(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "build_sjsdm_tuning_branch_work_items(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "pattern = map(data_sjsdm_tuning_branch_work_items)",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "build_sjsdm_cached_selected_folds(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "build_sjsdm_empty_selected_fold_artifacts()",
          fixed = TRUE
        )
        testthat::expect_false(
          stringr::str_detect(
            text_pipe,
            stringr::fixed("run_sjsdm_selected_candidate_folds(")
          )
        )
      }
    )
  }
)

testthat::test_that(
  "common CV execution publishes v2 and restartable internal targets",
  {
    vec_pipe_paths <-
      here::here(
        base::paste0(
          "R/Pipelines/_pipes/",
          "pipe_segment_model_cross_validation_execution.R"
        )
      )

    vec_public_names <-
      base::c(
        "data_sjsdm_candidate_fold_metrics",
        "data_sjsdm_candidate_repeat_summary",
        "list_sjsdm_selected_fold_artifacts",
        "data_sjsdm_out_of_fold_predictions",
        "data_sjsdm_out_of_fold_diagnostics",
        "list_sjsdm_cv_tuning_artifact",
        "list_sjsdm_cv_prediction_artifact"
      )

    purrr::walk(
      vec_pipe_paths,
      .f = ~ {
        text_pipe <-
          readr::read_file(.x)

        purrr::walk(
          vec_public_names,
          .f = ~ testthat::expect_match(
            text_pipe,
            stringr::str_glue('name = "{.x}"'),
            fixed = TRUE
          )
        )
      }
    )
  }
)

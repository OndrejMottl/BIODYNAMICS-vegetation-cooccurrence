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
          "fit_sjsdm_cross_validation_candidate(",
          fixed = TRUE
        )
        testthat::expect_match(
          text_pipe,
          "config_sjsdm_cv_fitting",
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
        "data_sjsdm_tuning_fit_attempts",
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

testthat::test_that(
  "low-taxon responses reach feasibility classification",
  {
    path_prepare_pipe <-
      here::here(
        "R/Pipelines/_pipes/pipe_segment_model_prepare_response.R"
      )
    path_cv_pipe <-
      here::here(
        base::paste0(
          "R/Pipelines/_pipes/",
          "pipe_segment_model_cross_validation_from_shared.R"
        )
      )

    text_prepare_pipe <-
      readr::read_file(path_prepare_pipe)
    text_cv_pipe <-
      readr::read_file(path_cv_pipe)

    testthat::expect_false(
      stringr::str_detect(
        text_prepare_pipe,
        stringr::fixed("validate_community_taxon_count(")
      )
    )
    testthat::expect_equal(
      stringr::str_count(
        text_cv_pipe,
        stringr::fixed(
          "data_community_matrix = data_community_filtered"
        )
      ),
      2L
    )
  }
)

testthat::test_that(
  "CV fit budgets invalidate fitting but not prepared folds",
  {
    text_shared_config <-
      readr::read_file(
        here::here("R/Pipelines/_pipes/pipe_segment_config_model.R")
      )
    text_resolution_config <-
      readr::read_file(
        here::here(
          "R/Pipelines/_pipes/pipe_segment_config_model_by_resolution.R"
        )
      )
    text_execution <-
      readr::read_file(
        here::here(
          base::paste0(
            "R/Pipelines/_pipes/",
            "pipe_segment_model_cross_validation_execution.R"
          )
        )
      )
    text_model_fit <-
      readr::read_file(
        here::here("R/Pipelines/_pipes/pipe_segment_model_fit.R")
      )
    text_prepared_target <-
      stringr::str_extract(
        text_execution,
        stringr::regex(
          base::paste0(
            'name = "list_sjsdm_prepared_tuning_folds".*?',
            'name = "data_sjsdm_all_tuning_work_items"'
          ),
          dotall = TRUE
        )
      )

    testthat::expect_match(
      text_shared_config,
      'base::setdiff(\n            base::names(config_cross_validation),',
      fixed = TRUE
    )
    testthat::expect_match(
      text_resolution_config,
      "purrr::list_modify(fit_budget = rlang::zap())",
      fixed = TRUE
    )
    testthat::expect_match(
      text_resolution_config,
      'value = c("_profile", "role")',
      fixed = TRUE
    )
    testthat::expect_match(
      text_resolution_config,
      ') == "main"',
      fixed = TRUE
    )
    testthat::expect_false(
      stringr::str_detect(
        text_prepared_target,
        stringr::fixed("config_sjsdm_cv_fitting")
      )
    )
    testthat::expect_match(
      text_execution,
      "config_sjsdm_cv_fitting = config_sjsdm_cv_fitting",
      fixed = TRUE
    )
    testthat::expect_match(
      text_model_fit,
      "base::invisible(config_sjsdm_cv_fitting)",
      fixed = TRUE
    )
    testthat::expect_match(
      text_model_fit,
      'sampling = config_model_fitting[["n_sampling"]]',
      fixed = TRUE
    )
  }
)

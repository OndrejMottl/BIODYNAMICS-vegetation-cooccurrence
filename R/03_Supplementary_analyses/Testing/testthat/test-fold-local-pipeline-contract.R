testthat::test_that(
  "CV pipe segments publish fold-local evaluation targets",
  {
    vec_pipe_paths <-
      base::c(
        here::here(
          "R/Pipelines/_pipes/pipe_segment_model_cross_validation.R"
        ),
        here::here(
          base::c(
            "R/Pipelines/_pipes/",
            "pipe_segment_model_cross_validation_from_shared.R"
          ) |>
            stringr::str_c(collapse = "")
        )
      )

    vec_pipe_text <-
      vec_pipe_paths |>
      purrr::map_chr(readr::read_file)

    vec_target_counts <-
      base::c(
        data_sjsdm_fold_local_metrics = 2L,
        list_sjsdm_fold_metric_summaries = 2L,
        list_sjsdm_metric_repeat_distributions = 1L
      )

    vec_function_names <-
      base::c(
        "evaluate_sjsdm_fold_predictions",
        "summarise_sjsdm_fold_metrics",
        "summarise_sjsdm_metric_repeats"
      )

    for (
      pipe_text in vec_pipe_text
    ) {
      for (
        target_name in base::names(vec_target_counts)
      ) {
        testthat::expect_equal(
          stringr::str_count(
            string = pipe_text,
            pattern = stringr::fixed(target_name)
          ),
          vec_target_counts[[target_name]]
        )
      }

      for (
        function_name in vec_function_names
      ) {
        testthat::expect_equal(
          stringr::str_count(
            string = pipe_text,
            pattern = stringr::fixed(function_name)
          ),
          1L
        )
      }

      testthat::expect_equal(
        stringr::str_count(
          string = pipe_text,
          pattern = stringr::fixed("model_evaluation_cross_validated")
        ),
        1L
      )
    }
  }
)

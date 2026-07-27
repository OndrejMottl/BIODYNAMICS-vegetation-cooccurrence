testthat::test_that(
  "CZ regularization reference exposes structured GPU evidence",
  {
    path_pipeline <-
      here::here(
        "R/Pipelines/pipeline_cz_paleo_cv_regularization_reference.R"
      )

    text_pipeline <-
      readr::read_file(path_pipeline)

    vec_target_names <-
      base::c(
        "data_sjsdm_structured_regularization_candidates",
        "data_sjsdm_structured_search_design",
        "data_sjsdm_structured_tuning_candidates",
        "data_sjsdm_structured_tuning_response_surface",
        "data_sjsdm_structured_selection_diagnostic",
        "list_sjsdm_structured_selected_fold_predictions",
        "data_sjsdm_structured_selected_fold_metrics",
        "list_sjsdm_structured_selected_repeat_distributions",
        "data_sjsdm_reference_taxon_eligibility",
        "list_sjsdm_structured_selection_guardrails",
        "list_sjsdm_structured_eligible_selection_guardrails"
      )

    purrr::walk(
      vec_target_names,
      ~ testthat::expect_match(text_pipeline, .x, fixed = TRUE)
    )

    testthat::expect_match(
      text_pipeline,
      "make_sjsdm_structured_regularization_candidates",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "score_sjsdm_joint_tuning_predictions",
      fixed = TRUE
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
    testthat::expect_match(
      text_pipeline,
      "assess_sjsdm_taxon_eligibility",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipeline,
      "assess_sjsdm_candidate_guardrails",
      fixed = TRUE
    )
    testthat::expect_false(
      stringr::str_detect(text_pipeline, "expand_grid")
    )

    path_runner <-
      here::here(
        "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_regularization_reference_gpu.R"
      )

    text_runner <-
      readr::read_file(path_runner)

    testthat::expect_match(
      text_runner,
      "project_cz_paleo_cv_regularization_reference_gpu",
      fixed = TRUE
    )
    testthat::expect_match(text_runner, "fresh_run = TRUE", fixed = TRUE)
  }
)

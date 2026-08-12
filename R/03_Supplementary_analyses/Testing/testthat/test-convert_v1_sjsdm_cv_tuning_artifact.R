testthat::test_that(
  "convert_v1_sjsdm_cv_tuning_artifact() upgrades the frozen v1 fixture",
  {
    data_candidates <-
      build_sjsdm_regularization_candidates(
        alpha_cov = 0,
        alpha_coef = 0,
        alpha_spatial = 0,
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1
      )

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "exhaustive",
        n_candidates = 1L,
        repeat_ids = 1L
      )

    data_empty_metrics <-
      build_sjsdm_empty_tuning_result()[["data_tuning"]]

    data_empty_summary <-
      summarise_sjsdm_tuning_candidates(data_empty_metrics) |>
      dplyr::mutate(
        source_id = base::character(),
        tier_id = base::character(),
        taxonomic_resolution = base::character(),
        response_family = base::character(),
        predictor_structure = base::character(),
        candidate_table_hash = base::character()
      )

    payload <-
      base::list(
        data_candidates = data_candidates,
        data_schedule = data_schedule,
        data_candidate_fold_metrics = data_empty_metrics,
        data_candidate_repeat_summary = data_empty_summary,
        data_stage_timings = summarise_sjsdm_tuning_timings(
          list_prediction_cache = base::list()
        ),
        data_execution_provenance = summarise_sjsdm_tuning_execution(
          data_tuning = data_empty_metrics,
          data_schedule = data_schedule
        ),
        list_prediction_cache = base::list()
      )

    res <-
      convert_v1_sjsdm_cv_tuning_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(res[["artifact_type"]], "sjsdm_cv_tuning")
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )
  }
)

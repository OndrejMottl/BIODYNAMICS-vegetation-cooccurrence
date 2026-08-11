testthat::test_that(
  "convert_v1_sjsdm_cv_evaluation_artifact() upgrades the frozen v1 fixture",
  {
    data_predictions <-
      build_sjsdm_empty_selected_fold_artifacts()[["data_predictions"]]

    list_pooled <-
      evaluate_sjsdm_cross_validated_predictions(data_predictions)

    data_fold_metrics <-
      evaluate_sjsdm_fold_predictions(data_predictions)

    list_fold_summaries <-
      summarise_sjsdm_fold_metrics(data_fold_metrics)

    list_repeat_distributions <-
      summarise_sjsdm_metric_repeats(list_fold_summaries)

    data_model_provenance <-
      summarise_sjsdm_model_provenance(
        data_feasibility = tibble::tibble(
          n_locations = 5L,
          n_samples = 20L,
          n_taxa = 4L,
          n_mem_locations = 5L,
          cv_strategy = "none",
          effective_folds = NA_integer_,
          cv_feasibility_status =
            "tier_pooled_regularization_required"
        ),
        data_regularization = tibble::tibble(
          tier_id = "paleo_spatial_local",
          taxonomic_resolution = "family",
          response_family = "binomial",
          predictor_structure = "spatial=TRUE;mode=spatial",
          candidate_table_hash = "candidate_hash",
          candidate_id = "candidate_001",
          regularization_source = "tier_pooled",
          source_tier = "paleo_spatial_local",
          selection_status = "selected"
        ),
        data_fold_diagnostics = tibble::tibble(),
        fit_device = "cpu"
      )

    payload <-
      base::list(
        list_pooled_evaluation = list_pooled,
        data_fold_metrics = data_fold_metrics,
        list_fold_summaries = list_fold_summaries,
        list_repeat_distributions = list_repeat_distributions,
        data_model_provenance = data_model_provenance
      )

    res <-
      convert_v1_sjsdm_cv_evaluation_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(res[["artifact_type"]], "sjsdm_cv_evaluation")
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )
  }
)

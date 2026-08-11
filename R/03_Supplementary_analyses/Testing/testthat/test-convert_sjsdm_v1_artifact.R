testthat::test_that(
  "convert_sjsdm_v1_artifact() requires the frozen fixture",
  {
    list_empty <-
      build_sjsdm_empty_selected_fold_artifacts()

    payload <-
      base::list(
        data_predictions = list_empty[["data_predictions"]],
        data_fold_diagnostics = list_empty[["data_diagnostics"]]
      )
    list_artifact <-
      convert_sjsdm_v1_artifact(
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        v1_schema_hash = "2d727fd54623501e0ac384e0674c17f3",
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        migration_function = "convert_v1_predictions",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_true(
      list_artifact[["provenance"]][["migration_applied"]]
    )
    testthat::expect_error(
      convert_sjsdm_v1_artifact(
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        v1_schema_hash = "unknown",
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        migration_function = "convert_v1_predictions"
      ),
      "not recognized"
    )
  }
)

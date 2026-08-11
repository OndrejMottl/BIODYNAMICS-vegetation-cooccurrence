testthat::test_that(
  "build_sjsdm_pipeline_artifact() builds native v2 output",
  {
    list_artifact <-
      build_sjsdm_pipeline_artifact(
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(
          data_predictions = tibble::tibble(value = 1),
          data_fold_diagnostics = tibble::tibble(status = "ok")
        ),
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(
      list_artifact[["provenance"]][["source_schema_version"]],
      "2.0.0"
    )
  }
)

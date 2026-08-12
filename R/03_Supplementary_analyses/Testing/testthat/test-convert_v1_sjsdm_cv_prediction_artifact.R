testthat::test_that(
  "convert_v1_sjsdm_cv_prediction_artifact() upgrades the frozen v1 fixture",
  {
    payload <-
      make_sjsdm_prediction_payload_fixture()

    res <-
      convert_v1_sjsdm_cv_prediction_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(res[["artifact_type"]], "sjsdm_cv_predictions")
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )
  }
)

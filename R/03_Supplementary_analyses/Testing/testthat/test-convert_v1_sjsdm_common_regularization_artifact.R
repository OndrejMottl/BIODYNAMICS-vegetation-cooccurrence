testthat::test_that(
  "convert_v1_sjsdm_common_regularization_artifact() upgrades v1",
  {
    payload <-
      make_sjsdm_common_payload_fixture(schema_version = "1.0.0")

    res <-
      convert_v1_sjsdm_common_regularization_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(
      res[["artifact_type"]],
      "sjsdm_common_regularization"
    )
    testthat::expect_identical(
      res[["payload"]][["data_regularization_selection"]][[
        "artifact_schema_version"
      ]],
      "2.0.0"
    )
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )

    payload_unknown <-
      make_sjsdm_common_payload_fixture(schema_version = "0.9.0")

    testthat::expect_error(
      convert_v1_sjsdm_common_regularization_artifact(
        payload = payload_unknown
      ),
      "frozen schema"
    )
  }
)

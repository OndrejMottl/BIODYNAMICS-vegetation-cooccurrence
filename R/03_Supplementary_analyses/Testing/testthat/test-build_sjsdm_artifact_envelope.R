testthat::test_that(
  "build_sjsdm_artifact_envelope() creates a valid envelope",
  {
    provenance <-
      tibble::tibble(
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC"),
        pipeline_id = "pipeline_paleo_core",
        configuration_profile = "project_cz_paleo",
        source_schema_version = "2.0.0",
        migration_applied = FALSE,
        migration_function = NA_character_
      )

    list_artifact <-
      build_sjsdm_empty_selected_fold_artifacts()

    payload <-
      base::list(
        data_predictions = list_artifact[["data_predictions"]],
        data_fold_diagnostics = list_artifact[["data_diagnostics"]]
      )

    list_artifact <-
      build_sjsdm_artifact_envelope(
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        provenance = provenance
      )

    testthat::expect_named(
      list_artifact,
      base::c(
        "schema_version",
        "artifact_type",
        "payload",
        "provenance",
        "content_hash"
      )
    )
    testthat::expect_identical(
      list_artifact[["schema_version"]],
      "2.0.0"
    )
    testthat::expect_true(
      validate_sjsdm_artifact_envelope(
        list_artifact = list_artifact,
        expected_artifact_type = "sjsdm_cv_predictions"
      )
    )
  }
)

testthat::test_that(
  "build_sjsdm_artifact_envelope() enforces payload names",
  {
    provenance <-
      tibble::tibble(
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC"),
        pipeline_id = "pipeline_paleo_core",
        configuration_profile = "project_cz_paleo",
        source_schema_version = "2.0.0",
        migration_applied = FALSE,
        migration_function = NA_character_
      )

    testthat::expect_error(
      build_sjsdm_artifact_envelope(
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(data_predictions = tibble::tibble()),
        provenance = provenance
      ),
      "payload"
    )
  }
)

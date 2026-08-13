testthat::test_that(
  "validate_sjsdm_artifact_envelope() accepts valid v2",
  {
    list_empty <-
      build_sjsdm_empty_selected_fold_artifacts()

    payload <-
      base::list(
        data_predictions = list_empty[["data_predictions"]],
        data_fold_diagnostics = list_empty[["data_diagnostics"]]
      )

    provenance <-
      tibble::tibble(
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC"),
        pipeline_id = "pipeline_paleo_core",
        configuration_profile = "project_cz_paleo",
        source_schema_version = "2.0.0",
        migration_applied = FALSE,
        migration_function = NA_character_
      )

    content_hash <-
      compute_sjsdm_artifact_content_hash(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        provenance = provenance
      )

    list_artifact <-
      base::list(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        provenance = provenance,
        content_hash = content_hash
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
  "validate_sjsdm_artifact_envelope() rejects migrated provenance",
  {
    list_empty <-
      build_sjsdm_empty_selected_fold_artifacts()

    provenance <-
      tibble::tibble(
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC"),
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        source_schema_version = "1.0.0",
        migration_applied = TRUE,
        migration_function = "retired_converter"
      )

    payload <-
      base::list(
        data_predictions = list_empty[["data_predictions"]],
        data_fold_diagnostics = list_empty[["data_diagnostics"]]
      )

    list_artifact <-
      base::list(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        provenance = provenance,
        content_hash = compute_sjsdm_artifact_content_hash(
          schema_version = "2.0.0",
          artifact_type = "sjsdm_cv_predictions",
          payload = payload,
          provenance = provenance
        )
      )

    testthat::expect_error(
      validate_sjsdm_artifact_envelope(
        list_artifact = list_artifact
      ),
      "provenance"
    )
  }
)

testthat::test_that(
  "validate_sjsdm_artifact_envelope() rejects invalid contracts",
  {
    list_artifact <-
      base::list(
        schema_version = "3.0.0",
        artifact_type = "unknown",
        payload = base::list(value = 1),
        provenance = tibble::tibble(value = 1),
        content_hash = "invalid"
      )

    testthat::expect_error(
      validate_sjsdm_artifact_envelope(
        list_artifact = list_artifact
      )
    )
  }
)

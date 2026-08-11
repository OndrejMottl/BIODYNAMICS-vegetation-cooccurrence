testthat::test_that(
  "compute_sjsdm_artifact_content_hash() is stable",
  {
    payload <-
      base::list(
        data_predictions = tibble::tibble(value = 1),
        data_fold_diagnostics = tibble::tibble(status = "ok")
      )

    provenance_native <-
      tibble::tibble(
        created_at = base::as.POSIXct(
          "2026-08-11 10:00:00",
          tz = "UTC"
        ),
        pipeline_id = "pipeline_paleo_core",
        configuration_profile = "project_cz_paleo",
        source_schema_version = "2.0.0",
        migration_applied = FALSE,
        migration_function = NA_character_,
        assignment_hash = "assignment"
      )

    provenance_migrated <-
      provenance_native |>
      dplyr::mutate(
        created_at = base::as.POSIXct(
          "2026-08-12 10:00:00",
          tz = "UTC"
        ),
        source_schema_version = "1.0.0",
        migration_applied = TRUE,
        migration_function = "upgrade_fixture"
      )

    hash_native <-
      compute_sjsdm_artifact_content_hash(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        provenance = provenance_native
      )

    hash_migrated <-
      compute_sjsdm_artifact_content_hash(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = payload,
        provenance = provenance_migrated
      )

    testthat::expect_match(hash_native, "^[0-9a-f]{16}$")
    testthat::expect_identical(hash_native, hash_migrated)
  }
)

testthat::test_that(
  "compute_sjsdm_artifact_content_hash() detects content changes",
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

    hash_one <-
      compute_sjsdm_artifact_content_hash(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(
          data_predictions = tibble::tibble(value = 1)
        ),
        provenance = provenance
      )

    hash_two <-
      compute_sjsdm_artifact_content_hash(
        schema_version = "2.0.0",
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(
          data_predictions = tibble::tibble(value = 2)
        ),
        provenance = provenance
      )

    testthat::expect_false(base::identical(hash_one, hash_two))
  }
)

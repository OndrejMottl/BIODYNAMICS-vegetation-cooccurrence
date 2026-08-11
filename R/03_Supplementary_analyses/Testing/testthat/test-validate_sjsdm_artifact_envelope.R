testthat::test_that(
  "validate_sjsdm_artifact_envelope() accepts valid v2",
  {
    payload <-
      base::list(
        data_predictions = tibble::tibble(value = 1),
        data_fold_diagnostics = tibble::tibble(status = "ok")
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
      digest::digest(
        base::list(
          schema_version = "2.0.0",
          artifact_type = "sjsdm_cv_predictions",
          payload = payload,
          provenance = provenance |>
            dplyr::select(
              -dplyr::all_of(
                base::c(
                  "created_at",
                  "source_schema_version",
                  "migration_applied",
                  "migration_function"
                )
              )
            )
        ),
        algo = "xxhash64"
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

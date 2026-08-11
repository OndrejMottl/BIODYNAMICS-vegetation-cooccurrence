testthat::test_that(
  "convert_v1_sjsdm_cv_tuning_artifact() upgrades the frozen v1 fixture",
  {
    vec_payload_names <-
      build_sjsdm_artifact_registry()[["sjsdm_cv_tuning"]]
    payload <-
      stats::setNames(
        purrr::map(
          vec_payload_names,
          ~ if (stringr::str_starts(.x, "list_")) {
            base::list()
          } else {
            tibble::tibble()
          }
        ),
        vec_payload_names
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


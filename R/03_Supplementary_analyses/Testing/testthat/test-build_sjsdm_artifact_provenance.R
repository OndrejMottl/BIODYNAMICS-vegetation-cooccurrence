testthat::test_that(
  "build_sjsdm_artifact_provenance() records native v2 sources",
  {
    data_native <-
      build_sjsdm_artifact_provenance(
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(
      data_native[["source_schema_version"]],
      "2.0.0"
    )
    testthat::expect_false(data_native[["migration_applied"]])
    testthat::expect_true(base::is.na(data_native[["migration_function"]]))
    testthat::expect_false(
      base::any(
        base::c(
          "source_schema_version",
          "migration_applied",
          "migration_function"
        ) %in%
          base::names(
            base::formals(build_sjsdm_artifact_provenance)
          )
      )
    )
  }
)

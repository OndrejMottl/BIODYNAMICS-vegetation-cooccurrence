testthat::test_that(
  "prepare_sjsdm_artifact_hash_payload() removes nested trace fields",
  {
    value <-
      base::list(
        data_selection = tibble::tibble(
          candidate_id = "candidate_001",
          created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
        ),
        list_nested = base::list(
          tibble::tibble(
            value = 1,
            migration_function = "convert_v1"
          )
        )
      )

    res <-
      prepare_sjsdm_artifact_hash_payload(value)

    testthat::expect_named(
      res[["data_selection"]],
      "candidate_id"
    )
    testthat::expect_named(
      res[["list_nested"]][[1L]],
      "value"
    )
  }
)

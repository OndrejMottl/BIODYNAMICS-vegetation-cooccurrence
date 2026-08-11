testthat::test_that(
  "validate_sjsdm_tier_tuning_payload() enforces exact tables",
  {
    payload <-
      make_sjsdm_tier_payload_fixture()

    testthat::expect_true(
      validate_sjsdm_tier_tuning_payload(payload)
    )

    payload_bad_type <-
      payload

    payload_bad_type[["data_candidate_aggregation"]][[
      "n_source_ids"
    ]] <-
      base::as.numeric(
        payload_bad_type[["data_candidate_aggregation"]][[
          "n_source_ids"
        ]]
      )

    testthat::expect_error(
      validate_sjsdm_tier_tuning_payload(payload_bad_type),
      "invalid column types"
    )

    payload_bad_status <-
      payload

    payload_bad_status[["data_source_candidate_loss"]][[
      "source_status"
    ]][[1L]] <-
      "unknown"

    testthat::expect_error(
      validate_sjsdm_tier_tuning_payload(payload_bad_status),
      "invalid status"
    )
  }
)

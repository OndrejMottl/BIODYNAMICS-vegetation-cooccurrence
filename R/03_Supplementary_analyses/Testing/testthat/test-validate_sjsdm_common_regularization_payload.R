testthat::test_that(
  "validate_sjsdm_common_regularization_payload() is exact",
  {
    payload <-
      make_sjsdm_common_payload_fixture()

    testthat::expect_true(
      validate_sjsdm_common_regularization_payload(payload)
    )

    payload_duplicate <-
      payload

    payload_duplicate[["data_model_index"]] <-
      dplyr::bind_rows(
        payload_duplicate[["data_model_index"]],
        payload_duplicate[["data_model_index"]]
      )

    testthat::expect_error(
      validate_sjsdm_common_regularization_payload(
        payload_duplicate
      ),
      "duplicate"
    )

    payload_bad_status <-
      payload

    payload_bad_status[["data_sensitivity_provenance"]][[
      "fit_status"
    ]] <-
      "unknown"

    testthat::expect_error(
      validate_sjsdm_common_regularization_payload(
        payload_bad_status
      ),
      "invalid status"
    )
  }
)

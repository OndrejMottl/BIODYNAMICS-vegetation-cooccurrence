testthat::test_that(
  base::paste(
    "validate_sjsdm_regularization_selection_payload() enforces",
    "its registered payload"
  ),
  {
    payload <-
      make_sjsdm_selection_payload_fixture()

    testthat::expect_true(
      validate_sjsdm_regularization_selection_payload(payload)
    )
    testthat::expect_error(
      validate_sjsdm_regularization_selection_payload(payload[-1L]),
      "registered contract"
    )
  }
)

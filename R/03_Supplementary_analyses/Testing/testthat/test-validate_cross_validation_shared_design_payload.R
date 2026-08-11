testthat::test_that(
  base::paste(
    "validate_cross_validation_shared_design_payload() enforces",
    "its registered payload"
  ),
  {
    payload <-
      make_cross_validation_shared_payload_fixture()

    testthat::expect_true(
      validate_cross_validation_shared_design_payload(payload)
    )
    testthat::expect_error(
      validate_cross_validation_shared_design_payload(payload[-1L]),
      "registered contract"
    )
  }
)

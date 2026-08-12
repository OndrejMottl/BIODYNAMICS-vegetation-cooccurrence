testthat::test_that(
  "validate_cross_validation_design_payload() enforces its registered payload",
  {
    payload <-
      make_cross_validation_design_payload_fixture()

    testthat::expect_true(
      validate_cross_validation_design_payload(payload)
    )
    testthat::expect_error(
      validate_cross_validation_design_payload(payload[-1L]),
      "registered contract"
    )
  }
)

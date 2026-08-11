testthat::test_that(
  "validate_sjsdm_cv_prediction_payload() enforces its registered payload",
  {
    payload <-
      make_sjsdm_prediction_payload_fixture()

    testthat::expect_true(
      validate_sjsdm_cv_prediction_payload(payload)
    )
    testthat::expect_error(
      validate_sjsdm_cv_prediction_payload(payload[-1L]),
      "registered contract"
    )
  }
)

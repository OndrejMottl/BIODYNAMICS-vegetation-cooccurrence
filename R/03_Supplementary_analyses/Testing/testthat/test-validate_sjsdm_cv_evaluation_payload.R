testthat::test_that(
  "validate_sjsdm_cv_evaluation_payload() enforces its registered payload",
  {
    vec_payload_names <-
      build_sjsdm_artifact_registry()[["sjsdm_cv_evaluation"]]
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

    testthat::expect_true(validate_sjsdm_cv_evaluation_payload(payload))
    testthat::expect_error(validate_sjsdm_cv_evaluation_payload(payload[-1L]), "registered contract")
  }
)


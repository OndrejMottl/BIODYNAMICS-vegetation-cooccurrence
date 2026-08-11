testthat::test_that(
  "validate_cross_validation_shared_design_payload() enforces its registered payload",
  {
    vec_payload_names <-
      build_sjsdm_artifact_registry()[["cross_validation_shared_design"]]
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

    testthat::expect_true(validate_cross_validation_shared_design_payload(payload))
    testthat::expect_error(validate_cross_validation_shared_design_payload(payload[-1L]), "registered contract")
  }
)


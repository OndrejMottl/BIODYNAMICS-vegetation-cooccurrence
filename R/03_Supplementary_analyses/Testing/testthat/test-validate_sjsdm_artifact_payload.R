testthat::test_that(
  "validate_sjsdm_artifact_payload() fails closed",
  {
    payload <-
      base::list(
        data_predictions = tibble::tibble(sample_id = 1L),
        data_fold_diagnostics = tibble::tibble(fold_id = 1L)
      )

    testthat::expect_true(
      validate_sjsdm_artifact_payload(
        artifact_type = "sjsdm_cv_predictions",
        payload = payload
      )
    )
    testthat::expect_error(
      validate_sjsdm_artifact_payload(
        artifact_type = "sjsdm_cv_predictions",
        payload = payload[1L]
      ),
      "registered contract"
    )
    testthat::expect_error(
      validate_sjsdm_artifact_payload(
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(
          data_predictions = tibble::tibble(
            sample_id = base::c(1L, 1L)
          ),
          data_fold_diagnostics = tibble::tibble()
        )
      ),
      "duplicate"
    )
  }
)

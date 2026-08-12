testthat::test_that(
  "validate_sjsdm_artifact_payload() fails closed",
  {
    list_empty <-
      build_sjsdm_empty_selected_fold_artifacts()

    payload <-
      base::list(
        data_predictions = list_empty[["data_predictions"]],
        data_fold_diagnostics = list_empty[["data_diagnostics"]]
      )

    testthat::expect_true(
      validate_sjsdm_cv_prediction_payload(payload = payload)
    )
    testthat::expect_error(
      validate_sjsdm_artifact_payload(
        artifact_type = "sjsdm_cv_predictions",
        payload = payload[1L]
      ),
      "registered contract"
    )
    testthat::expect_error(
      validate_sjsdm_cv_prediction_payload(
        payload = base::list(
          data_predictions = tibble::tibble(
            repeat_id = base::c(1L, 1L),
            fold_id = base::c(1L, 1L),
            row_index = base::c(1L, 1L),
            location_id = base::c("a", "a"),
            dataset_name = base::c("d", "d"),
            age = base::c(1, 1),
            taxon = base::c("t", "t"),
            observed = base::c(0, 0),
            predicted_probability = base::c(0.2, 0.3),
            null_probability = base::c(0.4, 0.4),
            prediction_status = base::c("ok", "ok")
          ),
          data_fold_diagnostics = list_empty[["data_diagnostics"]]
        )
      ),
      "duplicate keys"
    )
    testthat::expect_error(
      validate_sjsdm_cv_prediction_payload(
        payload = base::list(
          data_predictions = dplyr::mutate(
            list_empty[["data_predictions"]],
            row_index = base::as.numeric(.data[["row_index"]])
          ),
          data_fold_diagnostics = list_empty[["data_diagnostics"]]
        )
      ),
      "column types"
    )
  }
)

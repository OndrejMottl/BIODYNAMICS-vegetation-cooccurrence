testthat::test_that(
  "combine_sjsdm_selected_fold_artifacts() rejects duplicate coverage",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 1L,
        row_index = 1L,
        location_id = "a",
        dataset_name = "a",
        age = 0,
        taxon = "taxon_a",
        observed = 1,
        predicted_probability = 0.8,
        null_probability = 0.5,
        prediction_status = "ok"
      )

    data_diagnostics <-
      build_sjsdm_empty_selected_fold_artifacts()[["data_diagnostics"]]

    list_fold <-
      base::list(
        data_predictions = data_predictions,
        data_diagnostics = data_diagnostics
      )

    testthat::expect_error(
      combine_sjsdm_selected_fold_artifacts(
        list_fold_results = base::list(list_fold, list_fold),
        data_assignments = tibble::tibble(
          row_indices = base::list(1L)
        ),
        taxon_names = "taxon_a"
      ),
      "coverage"
    )
  }
)

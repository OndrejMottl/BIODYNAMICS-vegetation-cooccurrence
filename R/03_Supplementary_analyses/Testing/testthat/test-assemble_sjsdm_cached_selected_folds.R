testthat::test_that(
  "assemble_sjsdm_cached_selected_folds() reuses tuning probabilities",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("location_1", "location_2"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L),
        cv_strategy = "leave_one_location_out"
      )

    data_selected_candidate <-
      make_sjsdm_regularization_candidates(lambda_cov = 0) |>
      dplyr::mutate(regularization_source = "unit_cv")

    data_sample_ids <-
      tibble::tibble(
        dataset_name = base::c("location_1", "location_2"),
        age = base::c(0, 0),
        sample_id = base::c("sample_1", "sample_2"),
        row_index = 1:2,
        location_id = base::c("location_1", "location_2")
      )

    make_cache <- function(fold_id, sample_id, probability, fit_seed) {
      data_observed <-
        base::matrix(
          data = fold_id - 1L,
          nrow = 1L,
          dimnames = base::list(sample_id, "taxon_a")
        )

      return(
        base::list(
          list_fold_context = base::list(
            repeat_id = 1L,
            fold_id = fold_id,
            train_indices = base::setdiff(1:2, fold_id),
            test_indices = fold_id,
            n_train_locations = 1L,
            n_test_locations = 1L,
            n_train_samples = 1L,
            n_test_samples = 1L,
            cv_strategy = "leave_one_location_out"
          ),
          list_prepared_fold = base::list(
            data_train_observed = data_observed,
            data_test_observed = data_observed,
            data_test_observed_full = data_observed,
            test_sample_ids = sample_id,
            data_taxa_mapping = tibble::tibble(
              taxon = "taxon_a",
              retained = TRUE,
              status = "retained"
            ),
            n_effective_mev = 0L
          ),
          list_candidate_predictions = base::list(
            base::list(
              candidate_id = "candidate_001",
              fit_seed = fit_seed,
              fit_status = "ok",
              error_message = NA_character_,
              data_predicted = base::matrix(
                probability,
                nrow = 1L,
                dimnames = base::list(sample_id, "taxon_a")
              )
            )
          )
        )
      )
    }

    list_prediction_cache <-
      base::list(
        make_cache(1L, "sample_1", 0.2, 101L),
        make_cache(2L, "sample_2", 0.8, 102L)
      )

    list_result <-
      assemble_sjsdm_cached_selected_folds(
        data_assignments = data_assignments,
        data_selected_candidate = data_selected_candidate,
        data_sample_ids = data_sample_ids,
        taxon_names = "taxon_a",
        list_prediction_cache = list_prediction_cache
      )

    testthat::expect_identical(
      list_result[["data_predictions"]][["predicted_probability"]],
      base::c(0.2, 0.8)
    )
    testthat::expect_identical(
      list_result[["data_predictions"]][["prediction_status"]],
      base::rep("ok", 2L)
    )
    testthat::expect_identical(
      list_result[["data_diagnostics"]][["error_message"]],
      base::rep(NA_character_, 2L)
    )
    testthat::expect_identical(
      list_result[["data_diagnostics"]][["fit_seed"]],
      base::c(101L, 102L)
    )
    testthat::expect_identical(
      list_result[["data_diagnostics"]][["regularization_source"]],
      base::rep("unit_cv", 2L)
    )
  }
)

testthat::test_that(
  "assemble_sjsdm_cached_selected_folds() rejects missing fold caches",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 1L,
        location_id = "location_1",
        n_samples = 1L,
        row_indices = base::list(1L)
      )

    data_selected_candidate <-
      make_sjsdm_regularization_candidates(lambda_cov = 0) |>
      dplyr::mutate(regularization_source = "unit_cv")

    testthat::expect_error(
      assemble_sjsdm_cached_selected_folds(
        data_assignments = data_assignments,
        data_selected_candidate = data_selected_candidate,
        data_sample_ids = tibble::tibble(
          dataset_name = "location_1",
          age = 0
        ),
        taxon_names = "taxon_a",
        list_prediction_cache = base::list()
      ),
      "one cache entry"
    )
  }
)

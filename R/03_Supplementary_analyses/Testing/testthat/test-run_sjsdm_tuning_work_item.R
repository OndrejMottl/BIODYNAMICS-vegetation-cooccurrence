testthat::test_that(
  "granular tuning work items preserve the rich tuning contract",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L),
        cv_strategy = "leave_one_location_out"
      )

    data_candidates <-
      make_sjsdm_regularization_candidates(lambda_cov = 0)

    data_observed <-
      base::matrix(
        data = base::c(0, 1),
        nrow = 1L,
        dimnames = base::list("sample", base::c("a", "b"))
      )

    list_prepared_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = function(...) {
          base::list(
            data_train_input = base::list(data_spatial_to_fit = NULL),
            data_test_input = base::list(),
            data_train_observed = data_observed,
            data_test_observed = data_observed,
            data_test_observed_full = data_observed,
            test_sample_ids = "sample",
            data_taxa_mapping = tibble::tibble(
              taxon = base::c("a", "b"),
              retained = TRUE,
              status = "retained"
            )
          )
        }
      )

    data_work_items <-
      build_sjsdm_tuning_work_items(
        data_assignments = data_assignments,
        data_candidates = data_candidates
      )

    list_results <-
      purrr::map(
        base::seq_len(base::nrow(data_work_items)),
        ~ run_sjsdm_tuning_work_item(
          data_work_item = data_work_items[.x, ],
          list_prepared_folds = list_prepared_folds,
          fit_function = function(data_train_input, candidate, seed) {
            candidate
          },
          predict_function = function(object, data_test_input) {
            data_observed * 0.8 + 0.1
          },
          score_function = function(...) {
            base::list(
              n_taxa_retained = 2L,
              n_response_values = 2L,
              negative_log_likelihood_test = 0.4,
              negative_log_likelihood_per_response = 0.2,
              auc_macro_test = 1
            )
          }
        )
      )

    list_combined <-
      combine_sjsdm_tuning_work_items(list_results)

    testthat::expect_named(
      list_combined,
      base::c("data_tuning", "list_prediction_cache")
    )
    testthat::expect_equal(
      base::nrow(list_combined[["data_tuning"]]),
      2L
    )
    testthat::expect_length(
      list_combined[["list_prediction_cache"]],
      2L
    )
    testthat::expect_identical(
      purrr::map_int(
        list_combined[["list_prediction_cache"]],
        ~ base::length(.x[["list_candidate_predictions"]])
      ),
      base::rep(1L, 2L)
    )
  }
)

testthat::test_that(
  "combine_sjsdm_tuning_work_items() returns typed empty results",
  {
    list_combined <-
      combine_sjsdm_tuning_work_items(base::list())

    testthat::expect_equal(
      base::nrow(list_combined[["data_tuning"]]),
      0L
    )
    testthat::expect_length(
      list_combined[["list_prediction_cache"]],
      0L
    )
    testthat::expect_named(
      list_combined[["data_tuning"]],
      base::c(
        "repeat_id",
        "fold_id",
        "candidate_id",
        "alpha_cov",
        "alpha_coef",
        "alpha_spatial",
        "lambda_cov",
        "lambda_coef",
        "lambda_spatial",
        "fit_seed",
        "score_seed",
        "n_train_locations",
        "n_test_locations",
        "n_train_samples",
        "n_test_samples",
        "n_taxa_retained",
        "n_response_values",
        "negative_log_likelihood_test",
        "negative_log_likelihood_per_response",
        "auc_macro_test",
        "fit_status",
        "error_message",
        "cv_strategy",
        "regularization_source"
      )
    )
  }
)

testthat::test_that(
  "granular and monolithic tuning execution are equivalent",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L),
        cv_strategy = "leave_one_location_out"
      )

    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    data_observed <-
      base::matrix(
        data = base::c(0, 1),
        nrow = 1L,
        dimnames = base::list("sample", base::c("a", "b"))
      )

    prepare_fold_function <- function(...) {
      base::list(
        data_train_input = base::list(data_spatial_to_fit = NULL),
        data_test_input = base::list(),
        data_train_observed = data_observed,
        data_test_observed = data_observed,
        data_test_observed_full = data_observed,
        test_sample_ids = "sample",
        data_taxa_mapping = tibble::tibble(
          taxon = base::c("a", "b"),
          retained = TRUE,
          status = "retained"
        )
      )
    }

    fit_function <- function(data_train_input, candidate, seed) {
      base::list(candidate = candidate, seed = seed)
    }

    predict_function <- function(object, data_test_input) {
      base::matrix(
        data = object[["seed"]] %% 100L / 100,
        nrow = 1L,
        ncol = 2L
      )
    }

    score_function <- function(
        object,
        data_test_input,
        data_observed,
        data_predicted,
        epsilon,
        score_seed) {
      base::list(
        n_taxa_retained = 2L,
        n_response_values = 2L,
        negative_log_likelihood_test = base::sum(data_predicted),
        negative_log_likelihood_per_response =
          base::mean(data_predicted),
        auc_macro_test = score_seed %% 100L / 100
      )
    }

    list_monolithic <-
      run_sjsdm_tuning_candidates(
        data_assignments = data_assignments,
        data_candidates = data_candidates,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        retain_prediction_cache = TRUE
      )

    list_prepared_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = prepare_fold_function
      )

    data_work_items <-
      build_sjsdm_tuning_work_items(
        data_assignments = data_assignments,
        data_candidates = data_candidates
      )

    list_granular <-
      base::seq_len(base::nrow(data_work_items)) |>
      purrr::map(
        ~ run_sjsdm_tuning_work_item(
          data_work_item = data_work_items[.x, ],
          list_prepared_folds = list_prepared_folds,
          fit_function = fit_function,
          predict_function = predict_function,
          score_function = score_function
        )
      ) |>
      combine_sjsdm_tuning_work_items()

    testthat::expect_identical(
      list_granular[["data_tuning"]],
      list_monolithic[["data_tuning"]]
    )

    vec_monolithic_probabilities <-
      list_monolithic[["list_prediction_cache"]] |>
      purrr::map("list_candidate_predictions") |>
      purrr::list_flatten() |>
      purrr::map("data_predicted")

    vec_granular_probabilities <-
      list_granular[["list_prediction_cache"]] |>
      purrr::map("list_candidate_predictions") |>
      purrr::list_flatten() |>
      purrr::map("data_predicted")

    testthat::expect_identical(
      vec_granular_probabilities,
      vec_monolithic_probabilities
    )
  }
)

testthat::test_that(
  "granular work items retain isolated candidate failures",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L),
        cv_strategy = "leave_one_location_out"
      )

    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    data_observed <-
      base::matrix(0, nrow = 1L, ncol = 1L)

    list_prepared_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = function(...) {
          base::list(
            data_train_input = base::list(data_spatial_to_fit = NULL),
            data_test_input = base::list(),
            data_train_observed = data_observed,
            data_test_observed = data_observed,
            data_test_observed_full = data_observed,
            test_sample_ids = "sample",
            data_taxa_mapping = tibble::tibble(
              taxon = "a",
              retained = TRUE,
              status = "retained"
            )
          )
        }
      )

    data_work_items <-
      build_sjsdm_tuning_work_items(
        data_assignments = data_assignments,
        data_candidates = data_candidates
      )

    list_combined <-
      base::seq_len(base::nrow(data_work_items)) |>
      purrr::map(
        ~ run_sjsdm_tuning_work_item(
          data_work_item = data_work_items[.x, ],
          list_prepared_folds = list_prepared_folds,
          fit_function = function(data_train_input, candidate, seed) {
            if (
              candidate[["candidate_id"]][[1L]] == "candidate_002"
            ) {
              base::stop("candidate failed")
            }

            candidate
          },
          predict_function = function(object, data_test_input) {
            base::matrix(0.5, nrow = 1L, ncol = 1L)
          }
        )
      ) |>
      combine_sjsdm_tuning_work_items()

    testthat::expect_identical(
      list_combined[["data_tuning"]][["fit_status"]],
      base::rep(base::c("ok", "fit_error"), 2L)
    )
    testthat::expect_match(
      list_combined[["data_tuning"]][["error_message"]][
        list_combined[["data_tuning"]][["fit_status"]] ==
          "fit_error"
      ],
      "candidate failed",
      all = TRUE
    )
  }
)

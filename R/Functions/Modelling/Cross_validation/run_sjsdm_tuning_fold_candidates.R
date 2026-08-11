#' @title Run sjSDM Tuning Candidates for One Fold
#' @description
#' Prepares one fold once, then fits, predicts, and scores every regularization
#' candidate while preserving failures as compact status rows.
#' @param data_candidates
#' Candidate table returned by [build_sjsdm_regularization_candidates()].
#' @param list_fold_context
#' Fold metadata returned by [build_sjsdm_tuning_fold_context()].
#' @param prepare_fold_function,fit_function,predict_function,score_function
#' Injectable fold preparation, fit, prediction, and scoring functions
#' documented by
#' [run_sjsdm_tuning_candidates()].
#' @param seed
#' Non-negative base integer used to derive candidate fit and score seeds.
#' @param epsilon
#' Probability clipping tolerance passed to
#' [score_sjsdm_tuning_predictions()].
#' @param retain_prediction_cache
#' Logical. When true, return compact prepared-fold metadata and candidate
#' probability matrices alongside the unchanged tuning table.
#' @return
#' Compact candidate-by-fold tuning table with metrics and structured status.
#' When `retain_prediction_cache` is true, returns a named list containing that
#' table and a compact fold prediction cache without fitted model objects.
#' @export
run_sjsdm_tuning_fold_candidates <- function(
    data_candidates = NULL,
    list_fold_context = NULL,
    prepare_fold_function = NULL,
    fit_function = NULL,
    predict_function = NULL,
    score_function = score_sjsdm_tuning_predictions,
    seed = 900723L,
    epsilon = 1e-6,
    retain_prediction_cache = FALSE) {
  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_candidate_columns <-
    base::c("candidate_id", vec_parameter_columns)

  assertthat::assert_that(
    base::is.data.frame(data_candidates),
    base::nrow(data_candidates) > 0L,
    base::all(
      vec_candidate_columns %in% base::colnames(data_candidates)
    ),
    msg = "`data_candidates` is missing required columns."
  )

  vec_context_names <-
    base::c(
      "repeat_id",
      "fold_id",
      "train_indices",
      "test_indices",
      "n_train_locations",
      "n_test_locations",
      "n_train_samples",
      "n_test_samples",
      "cv_strategy"
    )

  assertthat::assert_that(
    base::is.list(list_fold_context),
    base::all(vec_context_names %in% base::names(list_fold_context)),
    msg = "`list_fold_context` is missing required elements."
  )

  assertthat::assert_that(
    base::is.function(prepare_fold_function),
    base::is.function(fit_function),
    base::is.function(predict_function),
    base::is.function(score_function),
    msg = "Fold preparation, fit, prediction, and scoring must be functions."
  )

  flag_valid_seed <-
    base::is.numeric(seed) &&
    base::length(seed) == 1L &&
    base::is.finite(seed) &&
    seed >= 0L &&
    seed <= .Machine[["integer.max"]] &&
    seed == base::as.integer(seed)

  assertthat::assert_that(
    flag_valid_seed,
    msg = "`seed` must be a single non-negative integer."
  )

  flag_valid_epsilon <-
    base::is.numeric(epsilon) &&
    base::length(epsilon) == 1L &&
    base::is.finite(epsilon) &&
    epsilon > 0 &&
    epsilon < 0.5

  assertthat::assert_that(
    flag_valid_epsilon,
    msg = "`epsilon` must be a finite number between zero and 0.5."
  )

  assertthat::assert_that(
    base::is.logical(retain_prediction_cache),
    base::length(retain_prediction_cache) == 1L,
    !base::is.na(retain_prediction_cache),
    msg = "retain_prediction_cache must be one logical value."
  )

  preparation_started <-
    base::proc.time()[["elapsed"]]

  list_fold <-
    tryCatch(
      expr = {
        list_prepared <-
          prepare_fold_function(
            train_indices = list_fold_context[["train_indices"]],
            test_indices = list_fold_context[["test_indices"]],
            repeat_id = list_fold_context[["repeat_id"]],
            fold_id = list_fold_context[["fold_id"]]
          )

        vec_required_fold_elements <-
          if (
            retain_prediction_cache
          ) {
            base::c(
              "data_train_input",
              "data_test_input",
              "data_train_observed",
              "data_test_observed",
              "data_test_observed_full",
              "test_sample_ids",
              "data_taxa_mapping"
            )
          } else {
            base::c(
              "data_train_input",
              "data_test_input",
              "data_test_observed"
            )
          }

        if (
          !base::is.list(list_prepared) ||
            !base::all(
              vec_required_fold_elements %in% base::names(list_prepared)
            ) ||
            !base::is.matrix(list_prepared[["data_test_observed"]])
        ) {
          cli::cli_abort("Fold preparation returned an invalid result.")
        }

        list_prepared
      },
      error = function(error_condition) {
        error_condition
      }
    )

  preparation_seconds <-
    base::proc.time()[["elapsed"]] - preparation_started

  data_fold_candidates <-
    data_candidates |>
    dplyr::mutate(
      repeat_id = list_fold_context[["repeat_id"]],
      fold_id = list_fold_context[["fold_id"]],
      fit_seed = NA_integer_,
      score_seed = NA_integer_,
      n_train_locations = list_fold_context[["n_train_locations"]],
      n_test_locations = list_fold_context[["n_test_locations"]],
      n_train_samples = list_fold_context[["n_train_samples"]],
      n_test_samples = list_fold_context[["n_test_samples"]],
      n_taxa_retained = NA_integer_,
      n_response_values = NA_integer_,
      negative_log_likelihood_test = NA_real_,
      negative_log_likelihood_per_response = NA_real_,
      auc_macro_test = NA_real_,
      fit_status = "preparation_error",
      error_message = if (
        base::inherits(list_fold, "error")
      ) {
        base::conditionMessage(list_fold)
      } else {
        NA_character_
      },
      cv_strategy = list_fold_context[["cv_strategy"]],
      regularization_source = "unit_cv",
      .before = 1L
    ) |>
    dplyr::select(
      "repeat_id",
      "fold_id",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
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

  if (
    base::inherits(list_fold, "error")
  ) {
    if (
      retain_prediction_cache
    ) {
      res_error <-
        base::list(
          data_tuning = data_fold_candidates,
          list_prediction_cache = base::list(
            list_fold_context = list_fold_context,
            list_prepared_fold = NULL,
            preparation_seconds = preparation_seconds,
            list_candidate_predictions = base::list()
          )
        )

      return(res_error)
    }

    return(data_fold_candidates)
  }

  list_candidate_results <-
    data_candidates |>
    dplyr::mutate(candidate_index = base::seq_len(dplyr::n())) |>
    dplyr::group_split(.data[["candidate_index"]]) |>
    purrr::map(
      .f = ~ run_sjsdm_prepared_tuning_candidate(
        data_candidate = dplyr::select(
          .data = .x,
          dplyr::all_of(vec_candidate_columns)
        ),
        list_prepared_fold = list_fold,
        list_fold_context = list_fold_context,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        seed = seed,
        epsilon = epsilon
      )
    )

  data_tuning <-
    list_candidate_results |>
    purrr::map("data_tuning") |>
    purrr::list_rbind()

  if (
    !retain_prediction_cache
  ) {
    return(data_tuning)
  }

  vec_cache_fold_elements <-
    base::c(
      "data_train_observed",
      "data_test_observed",
      "data_test_observed_full",
      "test_sample_ids",
      "data_taxa_mapping",
      "data_spatial_diagnostics"
    )

  list_prepared_fold_cache <-
    list_fold[
      base::intersect(
        vec_cache_fold_elements,
        base::names(list_fold)
      )
    ]

  data_spatial_train <-
    list_fold[["data_train_input"]][["data_spatial_to_fit"]]

  list_prepared_fold_cache[["n_effective_mev"]] <-
    if (
      base::is.null(data_spatial_train)
    ) {
      0L
    } else {
      base::ncol(data_spatial_train)
    }

  res <-
    base::list(
      data_tuning = data_tuning,
      list_prediction_cache = base::list(
        list_fold_context = list_fold_context,
        list_prepared_fold = list_prepared_fold_cache,
        preparation_seconds = preparation_seconds,
        list_candidate_predictions = list_candidate_results |>
          purrr::map("list_prediction")
      )
    )

  return(res)
}

#' @title Run sjSDM Tuning Candidates for One Fold
#' @description
#' Prepares one fold once, then fits, predicts, and scores every regularization
#' candidate while preserving failures as compact status rows.
#' @param data_candidates
#' Candidate table returned by [make_sjsdm_regularization_candidates()].
#' @param list_fold_context
#' Fold metadata returned by [make_sjsdm_tuning_fold_context()].
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

  data_observed <-
    list_fold[["data_test_observed"]]

  list_candidate_results <-
    data_fold_candidates |>
    dplyr::mutate(candidate_index = base::seq_len(dplyr::n())) |>
    dplyr::group_split(.data[["candidate_index"]]) |>
    purrr::map(
      .f = ~ {
        data_result <-
          .x |>
          dplyr::select(-"candidate_index")

        candidate_id <-
          .x[["candidate_id"]][[1L]]

        fit_seed_value <-
          stringr::str_c(
            seed,
            list_fold_context[["repeat_id"]],
            list_fold_context[["fold_id"]],
            candidate_id,
            "fit",
            sep = "|"
          ) |>
          digest::digest2int() |>
          base::as.double() |>
          base::`%%`(.Machine[["integer.max"]]) |>
          base::as.integer()

        score_seed_value <-
          stringr::str_c(
            seed,
            list_fold_context[["repeat_id"]],
            list_fold_context[["fold_id"]],
            candidate_id,
            "score",
            sep = "|"
          ) |>
          digest::digest2int() |>
          base::as.double() |>
          base::`%%`(.Machine[["integer.max"]]) |>
          base::as.integer()

        data_candidate <-
          data_result |>
          dplyr::select(dplyr::all_of(vec_candidate_columns))

        fit_started <-
          base::proc.time()[["elapsed"]]

        mod_fit <-
          tryCatch(
            expr = {
              fit_function(
                data_train_input = list_fold[["data_train_input"]],
                candidate = data_candidate,
                seed = fit_seed_value
              )
            },
            error = function(error_condition) {
              error_condition
            }
          )

        fit_seconds <-
          base::proc.time()[["elapsed"]] - fit_started

        data_result[["fit_seed"]] <-
          fit_seed_value

        data_result[["score_seed"]] <-
          score_seed_value

        if (
          base::inherits(mod_fit, "error")
        ) {
          data_result[["fit_status"]] <-
            "fit_error"

          data_result[["error_message"]] <-
            base::conditionMessage(mod_fit)

          return(
            base::list(
              data_tuning = data_result,
              list_prediction = base::list(
                candidate_id = candidate_id,
                fit_seed = fit_seed_value,
                fit_status = "fit_error",
                error_message = base::conditionMessage(mod_fit),
                data_predicted = NULL,
                fit_seconds = fit_seconds,
                prediction_seconds = NA_real_,
                scoring_seconds = NA_real_
              )
            )
          )

        }

        prediction_started <-
          base::proc.time()[["elapsed"]]

        data_predicted <-
          tryCatch(
            expr = {
              predict_function(
                object = mod_fit,
                data_test_input = list_fold[["data_test_input"]]
              )
            },
            error = function(error_condition) {
              error_condition
            }
          )

        prediction_seconds <-
          base::proc.time()[["elapsed"]] - prediction_started

        if (
          base::inherits(data_predicted, "error")
        ) {
          data_result[["fit_status"]] <-
            "prediction_error"

          data_result[["error_message"]] <-
            base::conditionMessage(data_predicted)

          return(
            base::list(
              data_tuning = data_result,
              list_prediction = base::list(
                candidate_id = candidate_id,
                fit_seed = fit_seed_value,
                fit_status = "prediction_error",
                error_message =
                  base::conditionMessage(data_predicted),
                data_predicted = NULL,
                fit_seconds = fit_seconds,
                prediction_seconds = prediction_seconds,
                scoring_seconds = NA_real_
              )
            )
          )

        }

        scoring_started <-
          base::proc.time()[["elapsed"]]

        data_metrics <-
          tryCatch(
            expr = {
              score_arguments <-
                base::list(
                  object = mod_fit,
                  data_test_input = list_fold[["data_test_input"]],
                  data_observed = data_observed,
                  data_predicted = data_predicted,
                  epsilon = epsilon
                )

              score_formal_names <-
                base::names(base::formals(score_function))

              if (
                "score_seed" %in% score_formal_names ||
                  "..." %in% score_formal_names
              ) {
                score_arguments[["score_seed"]] <-
                  score_seed_value
              }

              base::do.call(
                what = score_function,
                args = score_arguments
              )
            },
            error = function(error_condition) {
              error_condition
            }
          )

        scoring_seconds <-
          base::proc.time()[["elapsed"]] - scoring_started

        if (
          base::inherits(data_metrics, "error")
        ) {
          data_result[["fit_status"]] <-
            "scoring_error"

          data_result[["error_message"]] <-
            base::conditionMessage(data_metrics)

          return(
            base::list(
              data_tuning = data_result,
              list_prediction = base::list(
                candidate_id = candidate_id,
                fit_seed = fit_seed_value,
                fit_status = "scoring_error",
                error_message = base::conditionMessage(data_metrics),
                data_predicted = base::as.matrix(data_predicted),
                fit_seconds = fit_seconds,
                prediction_seconds = prediction_seconds,
                scoring_seconds = scoring_seconds
              )
            )
          )

        }

        vec_metric_names <-
          base::c(
            "n_taxa_retained",
            "n_response_values",
            "negative_log_likelihood_test",
            "negative_log_likelihood_per_response",
            "auc_macro_test"
          )

        data_result[vec_metric_names] <-
          data_metrics[vec_metric_names]

        data_result[["fit_status"]] <-
          "ok"

        data_result[["error_message"]] <-
          NA_character_

        return(
          base::list(
            data_tuning = data_result,
            list_prediction = base::list(
              candidate_id = candidate_id,
              fit_seed = fit_seed_value,
              fit_status = "ok",
              error_message = NA_character_,
              data_predicted = base::as.matrix(data_predicted),
              fit_seconds = fit_seconds,
              prediction_seconds = prediction_seconds,
              scoring_seconds = scoring_seconds
            )
          )
        )
      }
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

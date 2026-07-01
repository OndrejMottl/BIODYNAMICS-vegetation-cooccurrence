#' @title Run sjSDM Tuning Candidates for One Fold
#' @description
#' Prepares one fold once, then fits, predicts, and scores every regularization
#' candidate while preserving failures as compact status rows.
#' @param data_candidates
#' Candidate table returned by [make_sjsdm_regularization_candidates()].
#' @param list_fold_context
#' Fold metadata returned by [make_sjsdm_tuning_fold_context()].
#' @param prepare_fold_function,fit_function,predict_function
#' Injectable fold preparation, fit, and prediction functions documented by
#' [run_sjsdm_tuning_candidates()].
#' @param seed
#' Non-negative base integer used to derive candidate fit seeds.
#' @param epsilon
#' Probability clipping tolerance passed to
#' [score_sjsdm_tuning_predictions()].
#' @return
#' Compact candidate-by-fold tuning table with metrics and structured status.
#' @export
run_sjsdm_tuning_fold_candidates <- function(
    data_candidates = NULL,
    list_fold_context = NULL,
    prepare_fold_function = NULL,
    fit_function = NULL,
    predict_function = NULL,
    seed = 900723L,
    epsilon = 1e-6) {
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
    msg = "Fold preparation, fit, and prediction inputs must be functions."
  )

  flag_valid_seed <-
    base::is.numeric(seed) &&
    base::length(seed) == 1L &&
    base::is.finite(seed) &&
    seed >= 0L &&
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
          base::c(
            "data_train_input",
            "data_test_input",
            "data_test_observed"
          )

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

  data_fold_candidates <-
    data_candidates |>
    dplyr::mutate(
      repeat_id = list_fold_context[["repeat_id"]],
      fold_id = list_fold_context[["fold_id"]],
      fit_seed = NA_integer_,
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
    )

  if (
    base::inherits(list_fold, "error")
  ) {
    return(data_fold_candidates)
  }

  data_observed <-
    list_fold[["data_test_observed"]]

  res <-
    data_fold_candidates |>
    dplyr::mutate(candidate_index = base::seq_len(dplyr::n())) |>
    dplyr::group_split(.data[["candidate_index"]]) |>
    purrr::map(
      .f = ~ {
        data_result <-
          .x |>
          dplyr::select(-"candidate_index")

        candidate_index <-
          .x[["candidate_index"]][[1L]]

        fit_seed_value <-
          (
            base::as.double(seed) +
              list_fold_context[["repeat_id"]] * 100000 +
              list_fold_context[["fold_id"]] * 1000 +
              candidate_index
          ) %% .Machine[["integer.max"]] |>
          base::as.integer()

        data_candidate <-
          data_result |>
          dplyr::select(dplyr::all_of(vec_candidate_columns))

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

        data_result[["fit_seed"]] <-
          fit_seed_value

        if (
          base::inherits(mod_fit, "error")
        ) {
          data_result[["fit_status"]] <-
            "fit_error"

          data_result[["error_message"]] <-
            base::conditionMessage(mod_fit)

          return(data_result)
        }

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

        if (
          base::inherits(data_predicted, "error")
        ) {
          data_result[["fit_status"]] <-
            "prediction_error"

          data_result[["error_message"]] <-
            base::conditionMessage(data_predicted)

          return(data_result)
        }

        data_metrics <-
          tryCatch(
            expr = {
              score_sjsdm_tuning_predictions(
                data_observed = data_observed,
                data_predicted = data_predicted,
                epsilon = epsilon
              )
            },
            error = function(error_condition) {
              error_condition
            }
          )

        if (
          base::inherits(data_metrics, "error")
        ) {
          data_result[["fit_status"]] <-
            "scoring_error"

          data_result[["error_message"]] <-
            base::conditionMessage(data_metrics)

          return(data_result)
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

        return(data_result)
      }
    ) |>
    purrr::list_rbind()

  return(res)
}

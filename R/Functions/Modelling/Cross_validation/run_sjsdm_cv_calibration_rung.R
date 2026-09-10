#' @title Run One sjSDM CV Calibration Budget Rung
#' @description
#' Fits and scores every regularization candidate over cached prepared folds
#' for one or more repeats at one fixed iteration and sampling budget.
#' @param data_candidates
#' Complete regularization candidate table.
#' @param list_prepared_folds
#' Cached fold records from [prepare_sjsdm_tuning_folds()].
#' @param data_budget
#' One-row calibration ladder entry.
#' @param sel_abiotic_formula,config_sjsdm_cv_fitting
#' Model formula and validated structural CV fitting configuration.
#' @param repeat_ids
#' Integer repeats to execute.
#' @param seed,device
#' Deterministic seed and fitting device.
#' @param candidate_fit_function,predict_function,score_function
#' Injectable fitting, prediction, and scoring backends.
#' @return
#' List containing fold-level benchmark evidence and attempt-level provenance.
#' @export
run_sjsdm_cv_calibration_rung <- function(
    data_candidates = NULL,
    list_prepared_folds = NULL,
    data_budget = NULL,
    sel_abiotic_formula = NULL,
    config_sjsdm_cv_fitting = NULL,
    repeat_ids = 1L,
    seed = 900723L,
    device = "gpu",
    candidate_fit_function = fit_sjsdm_cross_validation_candidate,
    predict_function = predict_sjsdm_probability_matrix,
    score_function = score_sjsdm_joint_tuning_predictions) {
  vec_budget_columns <-
    base::c("budget_order", "n_iter", "n_sampling")

  assertthat::assert_that(
    base::is.data.frame(data_candidates),
    base::nrow(data_candidates) > 0L,
    base::is.list(list_prepared_folds),
    base::is.data.frame(data_budget),
    base::nrow(data_budget) == 1L,
    base::all(vec_budget_columns %in% base::colnames(data_budget)),
    base::is.list(config_sjsdm_cv_fitting),
    base::is.function(candidate_fit_function),
    base::is.function(predict_function),
    base::is.function(score_function),
    msg = "Calibration rung inputs are incomplete."
  )

  repeat_ids <-
    base::as.integer(repeat_ids)
  list_records <-
    list_prepared_folds |>
    purrr::keep(
      ~ .x[["list_fold_context"]][["repeat_id"]] %in% repeat_ids
    )

  assertthat::assert_that(
    base::length(list_records) > 0L,
    base::all(
      purrr::map_chr(list_records, "preparation_status") == "ok"
    ),
    msg = "Calibration requires complete cached prepared folds."
  )

  config_budget <-
    config_sjsdm_cv_fitting
  config_budget[["n_iter_initial"]] <-
    base::as.integer(data_budget[["n_iter"]][[1L]])
  config_budget[["n_iter_max"]] <-
    base::as.integer(data_budget[["n_iter"]][[1L]])
  config_budget[["n_sampling"]] <-
    base::as.integer(data_budget[["n_sampling"]][[1L]])

  data_work <-
    tidyr::crossing(
      fold_key = base::names(list_records),
      candidate_row = base::seq_len(base::nrow(data_candidates))
    )

  list_results <-
    purrr::map2(
      .x = data_work[["fold_key"]],
      .y = data_work[["candidate_row"]],
      .f = function(fold_key, candidate_row) {
        list_record <-
          list_records[[fold_key]]
        list_context <-
          list_record[["list_fold_context"]]
        data_candidate <-
          data_candidates[candidate_row, , drop = FALSE]

        run_sjsdm_prepared_tuning_candidate(
          data_candidate = data_candidate,
          list_prepared_fold = list_record[["list_prepared_fold"]],
          list_fold_context = list_context,
          fit_function = function(data_train_input, candidate, seed) {
            candidate_fit_function(
              data_train_input = data_train_input,
              candidate = candidate,
              sel_abiotic_formula = sel_abiotic_formula,
              config_sjsdm_cv_fitting = config_budget,
              seed = seed,
              repeat_id = list_context[["repeat_id"]],
              fold_id = list_context[["fold_id"]],
              device = device
            )
          },
          predict_function = predict_function,
          score_function = score_function,
          seed = seed
        )
      }
    )

  data_benchmark <-
    list_results |>
    purrr::map("data_tuning") |>
    purrr::list_rbind() |>
    dplyr::mutate(
      budget_order = base::as.integer(
        data_budget[["budget_order"]][[1L]]
      ),
      n_iter = base::as.integer(data_budget[["n_iter"]][[1L]]),
      n_sampling = base::as.integer(
        data_budget[["n_sampling"]][[1L]]
      ),
      normalized_loss = .data[[
        "negative_log_likelihood_per_response"
      ]],
      .before = 1L
    )

  data_fit_attempts <-
    list_results |>
    purrr::map(~ .x[["list_prediction"]][["data_fit_attempts"]]) |>
    purrr::compact() |>
    purrr::list_rbind()

  if (
    base::is.null(data_fit_attempts)
  ) {
    data_fit_attempts <-
      tibble::tibble()
  } else {
    data_fit_attempts <-
      data_fit_attempts |>
      dplyr::mutate(
        budget_order = base::as.integer(
          data_budget[["budget_order"]][[1L]]
        ),
        .before = 1L
      )
  }

  res <-
    base::list(
      data_benchmark = data_benchmark,
      data_fit_attempts = data_fit_attempts
    )

  return(res)
}

#' @title Run One sjSDM Tuning Work Item
#' @description
#' Fits, predicts, and scores one deterministic candidate/fold work item using
#' a previously prepared fold.
#' @param data_work_item
#' One-row work item from [build_sjsdm_tuning_branch_work_items()]. The optional
#' `tuning_applicable = FALSE` sentinel returns without fitting.
#' @param list_prepared_folds
#' Prepared fold list from [prepare_sjsdm_tuning_folds()].
#' @param fit_function,predict_function,score_function
#' Injectable functions documented by [run_sjsdm_tuning_candidates()].
#' @param epsilon
#' Probability clipping tolerance passed to the score function.
#' @return
#' Named list containing `work_item_id`, one-row `data_tuning`, and one compact
#' prediction-cache record. Fitted model objects are omitted.
#' @export
run_sjsdm_tuning_work_item <- function(
    data_work_item = NULL,
    list_prepared_folds = NULL,
    fit_function = NULL,
    predict_function = NULL,
    score_function = score_sjsdm_tuning_predictions,
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

  vec_work_item_columns <-
    base::c(
      "work_item_id",
      "fold_key",
      "repeat_id",
      "fold_id",
      "candidate_id",
      vec_parameter_columns,
      "tuning_seed"
    )

  assertthat::assert_that(
    base::is.data.frame(data_work_item),
    base::nrow(data_work_item) == 1L,
    base::all(
      vec_work_item_columns %in% base::colnames(data_work_item)
    ),
    base::is.list(list_prepared_folds),
    base::is.function(fit_function),
    base::is.function(predict_function),
    base::is.function(score_function),
    msg = "Granular tuning work-item inputs are incomplete."
  )

  tuning_applicable <-
    if (
      "tuning_applicable" %in% base::colnames(data_work_item)
    ) {
      data_work_item[["tuning_applicable"]][[1L]]
    } else {
      TRUE
    }

  assertthat::assert_that(
    base::is.logical(tuning_applicable),
    base::length(tuning_applicable) == 1L,
    !base::is.na(tuning_applicable),
    msg = "tuning_applicable must be one non-missing logical value."
  )

  if (
    !tuning_applicable
  ) {
    data_empty_tuning <-
      build_sjsdm_empty_tuning_result() |>
      purrr::chuck("data_tuning")

    res_not_applicable <-
      base::list(
        work_item_id = data_work_item[["work_item_id"]][[1L]],
        data_tuning = data_empty_tuning,
        list_prediction_cache = NULL
      )

    return(res_not_applicable)
  }

  fold_key <-
    data_work_item[["fold_key"]][[1L]]

  list_prepared_record <-
    list_prepared_folds[[fold_key]]

  if (
    base::is.null(list_prepared_record)
  ) {
    cli::cli_abort("The work item's prepared fold is unavailable.")
  }

  data_candidate <-
    data_work_item |>
    dplyr::select(
      "candidate_id",
      dplyr::all_of(vec_parameter_columns)
    )

  list_fold_context <-
    list_prepared_record[["list_fold_context"]]

  list_prepared_fold <-
    list_prepared_record[["list_prepared_fold"]]

  vec_required_fold_elements <-
    base::c(
      "data_train_input",
      "data_test_input",
      "data_train_observed",
      "data_test_observed",
      "data_test_observed_full",
      "test_sample_ids",
      "data_taxa_mapping"
    )

  flag_valid_preparation <-
    base::identical(
      list_prepared_record[["preparation_status"]],
      "ok"
    ) &&
    base::is.list(list_prepared_fold) &&
    base::all(
      vec_required_fold_elements %in% base::names(list_prepared_fold)
    ) &&
    base::is.matrix(list_prepared_fold[["data_test_observed"]])

  if (
    !flag_valid_preparation
  ) {
    error_message <-
      if (
        base::identical(
          list_prepared_record[["preparation_status"]],
          "ok"
        )
      ) {
        "Fold preparation returned an invalid result."
      } else {
        list_prepared_record[["error_message"]]
      }

    list_candidate_result <-
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_fold_context,
        fit_status = "preparation_error",
        error_message = error_message
      )

    list_prediction_cache <-
      base::list(
        list_fold_context = list_fold_context,
        list_prepared_fold = NULL,
        preparation_seconds =
          list_prepared_record[["preparation_seconds"]],
        list_candidate_predictions = base::list()
      )
  } else {
    list_candidate_result <-
      run_sjsdm_prepared_tuning_candidate(
        data_candidate = data_candidate,
        list_prepared_fold = list_prepared_fold,
        list_fold_context = list_fold_context,
        fit_function = fit_function,
        predict_function = predict_function,
        score_function = score_function,
        seed = data_work_item[["tuning_seed"]][[1L]],
        epsilon = epsilon
      )

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
      list_prepared_fold[
        base::intersect(
          vec_cache_fold_elements,
          base::names(list_prepared_fold)
        )
      ]

    data_spatial_train <-
      list_prepared_fold[["data_train_input"]][[
        "data_spatial_to_fit"
      ]]

    list_prepared_fold_cache[["n_effective_mev"]] <-
      if (
        base::is.null(data_spatial_train)
      ) {
        0L
      } else {
        base::ncol(data_spatial_train)
      }

    list_prediction_cache <-
      base::list(
        list_fold_context = list_fold_context,
        list_prepared_fold = list_prepared_fold_cache,
        preparation_seconds =
          list_prepared_record[["preparation_seconds"]],
        list_candidate_predictions =
          base::list(list_candidate_result[["list_prediction"]])
      )
  }

  res <-
    base::list(
      work_item_id = data_work_item[["work_item_id"]][[1L]],
      data_tuning = list_candidate_result[["data_tuning"]],
      list_prediction_cache = list_prediction_cache
    )

  return(res)
}

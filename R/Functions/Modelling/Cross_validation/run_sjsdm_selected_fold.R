#' @title Run One Selected sjSDM Fold
#' @description
#' Prepares, fits, and predicts one live selected-candidate fold, then delegates
#' all persisted row construction to [build_sjsdm_selected_fold_artifacts()].
#' @param list_fold_context
#' Fold context returned by [build_sjsdm_tuning_fold_context()].
#' @param data_candidate
#' One-row selected candidate table without provenance-only fields.
#' @param data_sample_ids,taxon_names
#' Normalized sample metadata and full ordered response-taxon names.
#' @param regularization_source
#' Source label for the selected regularization candidate.
#' @param prepare_fold_function,fit_function,predict_function
#' Injectable selected-fold lifecycle functions.
#' @param seed
#' Non-negative base integer used to derive the stable fold fit seed.
#' @return
#' Named list with one fold's prediction and diagnostic artifacts.
#' @export
run_sjsdm_selected_fold <- function(
    list_fold_context = NULL,
    data_candidate = NULL,
    data_sample_ids = NULL,
    taxon_names = NULL,
    regularization_source = NULL,
    prepare_fold_function = NULL,
    fit_function = NULL,
    predict_function = NULL,
    seed = 900723L) {
  vec_candidate_columns <-
    base::c(
      "candidate_id",
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_context_names <-
    base::c(
      "repeat_id",
      "fold_id",
      "train_indices",
      "test_indices",
      "n_train_samples",
      "n_test_samples",
      "cv_strategy"
    )

  assertthat::assert_that(
    base::is.list(list_fold_context),
    base::all(vec_context_names %in% base::names(list_fold_context)),
    base::is.data.frame(data_candidate),
    base::nrow(data_candidate) == 1L,
    base::all(vec_candidate_columns %in% base::colnames(data_candidate)),
    base::is.data.frame(data_sample_ids),
    base::is.character(taxon_names),
    base::is.character(regularization_source),
    base::length(regularization_source) == 1L,
    base::is.function(prepare_fold_function),
    base::is.function(fit_function),
    base::is.function(predict_function),
    msg = "Selected-fold execution inputs are incomplete."
  )

  fit_seed <-
    base::as.integer(
      (
        base::as.double(seed) +
          list_fold_context[["repeat_id"]] * 100000 +
          list_fold_context[["fold_id"]] * 1000 +
          1L
      ) %% .Machine[["integer.max"]]
    )

  list_prepared_fold <-
    base::tryCatch(
      expr = prepare_fold_function(
        train_indices = list_fold_context[["train_indices"]],
        test_indices = list_fold_context[["test_indices"]],
        repeat_id = list_fold_context[["repeat_id"]],
        fold_id = list_fold_context[["fold_id"]]
      ),
      error = base::identity
    )

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

  flag_preparation_error <-
    base::inherits(list_prepared_fold, "error") ||
    !base::is.list(list_prepared_fold) ||
    !base::all(
      vec_required_fold_elements %in% base::names(list_prepared_fold)
    )

  if (
    !flag_preparation_error
  ) {
    data_test_observed_full <-
      list_prepared_fold[["data_test_observed_full"]]

    data_taxa_mapping <-
      list_prepared_fold[["data_taxa_mapping"]]

    flag_preparation_error <-
      !base::is.matrix(data_test_observed_full) ||
      !base::is.numeric(data_test_observed_full) ||
      !base::is.data.frame(data_taxa_mapping) ||
      !base::identical(
        base::colnames(data_test_observed_full),
        taxon_names
      ) ||
      !base::identical(
        base::rownames(data_test_observed_full),
        list_prepared_fold[["test_sample_ids"]]
      ) ||
      !base::identical(data_taxa_mapping[["taxon"]], taxon_names)
  }

  if (
    flag_preparation_error
  ) {
    error_message <-
      if (
        base::inherits(list_prepared_fold, "error")
      ) {
        base::conditionMessage(list_prepared_fold)
      } else if (
        !base::is.list(list_prepared_fold) ||
          !base::all(
            vec_required_fold_elements %in%
              base::names(list_prepared_fold)
          )
      ) {
        "Fold preparation returned an invalid result."
      } else {
        "Fold preparation outputs are not aligned."
      }

    data_predictions <-
      build_sjsdm_fold_prediction_skeleton(
        list_fold_context = list_fold_context,
        data_sample_ids = data_sample_ids,
        taxon_names = taxon_names,
        prediction_status = "preparation_error"
      )

    data_diagnostics <-
      tibble::tibble(
        repeat_id = list_fold_context[["repeat_id"]],
        fold_id = list_fold_context[["fold_id"]],
        candidate_id = data_candidate[["candidate_id"]][[1L]],
        fit_seed = fit_seed,
        n_train_samples = list_fold_context[["n_train_samples"]],
        n_test_samples = list_fold_context[["n_test_samples"]],
        n_taxa_retained = NA_integer_,
        n_effective_mev = NA_integer_,
        fit_status = "preparation_error",
        error_message = error_message,
        cv_strategy = list_fold_context[["cv_strategy"]],
        regularization_source = regularization_source
      )

    return(
      base::list(
        data_predictions = data_predictions,
        data_diagnostics = data_diagnostics
      )
    )
  }

  mod_fit <-
    base::tryCatch(
      expr = fit_function(
        data_train_input =
          list_prepared_fold[["data_train_input"]],
        candidate = data_candidate,
        seed = fit_seed
      ),
      error = base::identity
    )

  data_predicted <-
    if (
      base::inherits(mod_fit, "error")
    ) {
      NULL
    } else {
      base::tryCatch(
        expr = predict_function(
          object = mod_fit,
          data_test_input =
            list_prepared_fold[["data_test_input"]]
        ),
        error = base::identity
      )
    }

  fold_status <-
    if (
      base::inherits(mod_fit, "error")
    ) {
      "fit_error"
    } else if (
      base::inherits(data_predicted, "error")
    ) {
      "prediction_error"
    } else {
      "ok"
    }

  error_message <-
    if (
      base::inherits(mod_fit, "error")
    ) {
      base::conditionMessage(mod_fit)
    } else if (
      base::inherits(data_predicted, "error")
    ) {
      base::conditionMessage(data_predicted)
    } else {
      NA_character_
    }

  if (
    base::inherits(data_predicted, "error")
  ) {
    data_predicted <- NULL
  }

  res <-
    build_sjsdm_selected_fold_artifacts(
      list_prepared_fold = list_prepared_fold,
      list_fold_context = list_fold_context,
      data_sample_ids = data_sample_ids,
      taxon_names = taxon_names,
      candidate_id = data_candidate[["candidate_id"]][[1L]],
      fit_seed = fit_seed,
      regularization_source = regularization_source,
      data_predicted = data_predicted,
      fold_status = fold_status,
      error_message = error_message
    )

  return(res)
}

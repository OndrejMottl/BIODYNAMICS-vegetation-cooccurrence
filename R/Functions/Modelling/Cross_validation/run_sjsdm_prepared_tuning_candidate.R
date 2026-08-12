#' @title Run One Prepared sjSDM Tuning Candidate
#' @description
#' Fits, predicts, and scores one regularization candidate against one
#' previously prepared cross-validation fold.
#' @param data_candidate
#' One-row candidate table with candidate ID and six regularization values.
#' @param list_prepared_fold
#' Prepared fold containing train input, test input, and observed test data.
#' @param list_fold_context
#' Fold identifiers, sample/location counts, and cross-validation strategy.
#' @param fit_function,predict_function,score_function
#' Injectable fitting, prediction, and scoring functions.
#' @param seed
#' Non-negative base integer used to derive fit and score seeds.
#' @param epsilon
#' Probability clipping tolerance passed to the score function.
#' @return
#' Named list containing one-row `data_tuning` and compact
#' `list_prediction` output without a fitted model object.
#' @examples
#' \dontrun{
#' run_sjsdm_prepared_tuning_candidate(
#'   data_candidate = data_candidate,
#'   list_prepared_fold = list_prepared_fold,
#'   list_fold_context = list_fold_context,
#'   fit_function = fit_sjsdm_model,
#'   predict_function = predict_sjsdm_model
#' )
#' }
#' @export
run_sjsdm_prepared_tuning_candidate <- function(
    data_candidate = NULL,
    list_prepared_fold = NULL,
    list_fold_context = NULL,
    fit_function = NULL,
    predict_function = NULL,
    score_function = score_sjsdm_tuning_predictions,
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
    base::is.data.frame(data_candidate),
    base::nrow(data_candidate) == 1L,
    base::all(
      vec_candidate_columns %in% base::colnames(data_candidate)
    ),
    msg = "data_candidate must contain one complete candidate."
  )

  vec_prepared_names <-
    base::c(
      "data_train_input",
      "data_test_input",
      "data_test_observed"
    )

  assertthat::assert_that(
    base::is.list(list_prepared_fold),
    base::all(
      vec_prepared_names %in% base::names(list_prepared_fold)
    ),
    base::is.matrix(list_prepared_fold[["data_test_observed"]]),
    msg = "list_prepared_fold is incomplete."
  )

  vec_context_names <-
    base::c(
      "repeat_id",
      "fold_id",
      "n_train_locations",
      "n_test_locations",
      "n_train_samples",
      "n_test_samples",
      "cv_strategy"
    )

  assertthat::assert_that(
    base::is.list(list_fold_context),
    base::all(vec_context_names %in% base::names(list_fold_context)),
    msg = "list_fold_context is incomplete."
  )

  assertthat::assert_that(
    base::is.function(fit_function),
    base::is.function(predict_function),
    base::is.function(score_function),
    msg = "Fit, prediction, and scoring inputs must be functions."
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
    msg = "seed must be one non-negative integer."
  )

  flag_valid_epsilon <-
    base::is.numeric(epsilon) &&
    base::length(epsilon) == 1L &&
    base::is.finite(epsilon) &&
    epsilon > 0 &&
    epsilon < 0.5

  assertthat::assert_that(
    flag_valid_epsilon,
    msg = "epsilon must be a finite number between zero and 0.5."
  )

  candidate_id <-
    data_candidate[["candidate_id"]][[1L]]

  fit_seed <-
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

  score_seed <-
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

  fit_started <-
    base::proc.time()[["elapsed"]]

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

  fit_seconds <-
    base::proc.time()[["elapsed"]] - fit_started

  if (
    base::inherits(mod_fit, "error")
  ) {
    list_fit_error <-
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_fold_context,
        fit_seed = fit_seed,
        score_seed = score_seed,
        fit_status = "fit_error",
        error_message = base::conditionMessage(mod_fit),
        fit_seconds = fit_seconds
      )

    return(list_fit_error)
  }

  prediction_started <-
    base::proc.time()[["elapsed"]]

  data_predicted <-
    base::tryCatch(
      expr = predict_function(
        object = mod_fit,
        data_test_input = list_prepared_fold[["data_test_input"]]
      ),
      error = base::identity
    )

  prediction_seconds <-
    base::proc.time()[["elapsed"]] - prediction_started

  if (
    base::inherits(data_predicted, "error")
  ) {
    list_prediction_error <-
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_fold_context,
        fit_seed = fit_seed,
        score_seed = score_seed,
        fit_status = "prediction_error",
        error_message = base::conditionMessage(data_predicted),
        fit_seconds = fit_seconds,
        prediction_seconds = prediction_seconds
      )

    return(list_prediction_error)
  }

  scoring_started <-
    base::proc.time()[["elapsed"]]

  data_metrics <-
    base::tryCatch(
      expr = {
        list_score_arguments <-
          base::list(
            object = mod_fit,
            data_test_input =
              list_prepared_fold[["data_test_input"]],
            data_observed =
              list_prepared_fold[["data_test_observed"]],
            data_predicted = data_predicted,
            epsilon = epsilon
          )

        vec_score_formals <-
          base::names(base::formals(score_function))

        if (
          "score_seed" %in% vec_score_formals ||
            "..." %in% vec_score_formals
        ) {
          list_score_arguments[["score_seed"]] <-
            score_seed
        }

        rlang::exec(
          .fn = score_function,
          !!!list_score_arguments
        )
      },
      error = base::identity
    )

  scoring_seconds <-
    base::proc.time()[["elapsed"]] - scoring_started

  if (
    base::inherits(data_metrics, "error")
  ) {
    list_scoring_error <-
      build_sjsdm_candidate_fold_result(
        data_candidate = data_candidate,
        list_fold_context = list_fold_context,
        fit_seed = fit_seed,
        score_seed = score_seed,
        fit_status = "scoring_error",
        error_message = base::conditionMessage(data_metrics),
        data_predicted = data_predicted,
        fit_seconds = fit_seconds,
        prediction_seconds = prediction_seconds,
        scoring_seconds = scoring_seconds
      )

    return(list_scoring_error)
  }

  list_result <-
    build_sjsdm_candidate_fold_result(
      data_candidate = data_candidate,
      list_fold_context = list_fold_context,
      fit_seed = fit_seed,
      score_seed = score_seed,
      fit_status = "ok",
      data_metrics = data_metrics,
      data_predicted = data_predicted,
      fit_seconds = fit_seconds,
      prediction_seconds = prediction_seconds,
      scoring_seconds = scoring_seconds
    )

  return(list_result)
}

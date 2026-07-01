#' @title Run sjSDM Tuning Candidates
#' @description
#' Fits every deterministic regularization candidate independently on each
#' cross-validation training partition and scores held-out probabilities.
#' @param data_assignments
#' Location-level assignment table with `repeat_id`, `fold_id`, `location_id`,
#' `n_samples`, and `row_indices`. Optional `cv_strategy` is propagated.
#' @param data_candidates
#' Candidate table returned by [make_sjsdm_regularization_candidates()].
#' @param prepare_fold_function
#' Injectable function called with `train_indices`, `test_indices`,
#' `repeat_id`, and `fold_id`. It must return `data_train_input`,
#' `data_test_input`, and matrix `data_test_observed`.
#' @param fit_function
#' Injectable function called with `data_train_input`, one-row `candidate`,
#' and deterministic integer `seed`.
#' @param predict_function
#' Injectable function called with fitted `object` and `data_test_input`. It
#' must return a probability matrix aligned to `data_test_observed`.
#' @param seed
#' Single non-negative integer used to derive stable fit seeds. Defaults to
#' `900723L`.
#' @param epsilon
#' Probability clipping tolerance used for held-out log loss. Defaults to
#' `1e-6`.
#' @return
#' Compact tibble with one row per repeat, fold, and candidate. It contains
#' candidate parameters, fold counts, total and per-response held-out negative
#' log likelihood, macro AUC, fit status, error text, CV strategy, and
#' regularization source. Fitted objects and prediction matrices are omitted.
#' @details
#' Fold preparation is run once per repeat and fold. Preparation, fit,
#' prediction, and scoring errors are retained as structured status rows so a
#' failed candidate does not abort the remaining tuning grid.
#' @export
run_sjsdm_tuning_candidates <- function(
    data_assignments = NULL,
    data_candidates = NULL,
    prepare_fold_function = NULL,
    fit_function = NULL,
    predict_function = NULL,
    seed = 900723L,
    epsilon = 1e-6) {
  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::nrow(data_assignments) > 0L,
    msg = "`data_assignments` must be a non-empty data frame."
  )

  vec_required_assignment_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "location_id",
      "n_samples",
      "row_indices"
    )

  assertthat::assert_that(
    base::all(
      vec_required_assignment_columns %in%
        base::colnames(data_assignments)
    ),
    msg = "`data_assignments` is missing required columns."
  )

  assertthat::assert_that(
    base::is.data.frame(data_candidates),
    base::nrow(data_candidates) > 0L,
    msg = "`data_candidates` must be a non-empty data frame."
  )

  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_required_candidate_columns <-
    base::c("candidate_id", vec_parameter_columns)

  assertthat::assert_that(
    base::all(
      vec_required_candidate_columns %in%
        base::colnames(data_candidates)
    ),
    msg = "`data_candidates` is missing required columns."
  )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        data_candidates[vec_parameter_columns],
        base::is.numeric
      )
    ),
    base::all(
      base::is.finite(
        base::as.matrix(data_candidates[vec_parameter_columns])
      )
    ),
    msg = "Candidate parameters must contain finite numeric values."
  )

  vec_candidate_ids <-
    data_candidates |>
    dplyr::pull("candidate_id")

  assertthat::assert_that(
    base::is.character(vec_candidate_ids),
    base::all(!base::is.na(vec_candidate_ids)),
    base::all(base::nzchar(vec_candidate_ids)),
    !base::any(base::duplicated(vec_candidate_ids)),
    msg = "`candidate_id` must contain unique non-missing strings."
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

  vec_repeat_ids <-
    data_assignments |>
    dplyr::pull("repeat_id")

  vec_fold_ids <-
    data_assignments |>
    dplyr::pull("fold_id")

  assertthat::assert_that(
    base::is.numeric(vec_repeat_ids),
    base::all(base::is.finite(vec_repeat_ids)),
    base::all(vec_repeat_ids >= 1L),
    base::all(vec_repeat_ids == base::as.integer(vec_repeat_ids)),
    msg = "`repeat_id` must contain positive integers."
  )

  assertthat::assert_that(
    base::is.numeric(vec_fold_ids),
    base::all(base::is.finite(vec_fold_ids)),
    base::all(vec_fold_ids >= 1L),
    base::all(vec_fold_ids == base::as.integer(vec_fold_ids)),
    msg = "`fold_id` must contain positive integers."
  )

  assertthat::assert_that(
    base::is.list(data_assignments[["row_indices"]]),
    msg = "`row_indices` must be a list column."
  )

  data_duplicate_locations <-
    data_assignments |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["location_id"]],
      name = "n_assignments"
    ) |>
    dplyr::filter(.data[["n_assignments"]] != 1L)

  if (
    base::nrow(data_duplicate_locations) > 0L
  ) {
    cli::cli_abort("Every location must occur once in each repeat.")
  }

  data_fold_keys <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  res <-
    purrr::map2(
      .x = data_fold_keys[["repeat_id"]],
      .y = data_fold_keys[["fold_id"]],
      .f = ~ {
        list_fold_context <-
          make_sjsdm_tuning_fold_context(
            data_assignments = data_assignments,
            repeat_id = .x,
            fold_id = .y
          )

        run_sjsdm_tuning_fold_candidates(
          data_candidates = data_candidates,
          list_fold_context = list_fold_context,
          prepare_fold_function = prepare_fold_function,
          fit_function = fit_function,
          predict_function = predict_function,
          seed = seed,
          epsilon = epsilon
        )
      }
    ) |>
    purrr::list_rbind() |>
    dplyr::select(
      "repeat_id",
      "fold_id",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
      "fit_seed",
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

  return(res)
}

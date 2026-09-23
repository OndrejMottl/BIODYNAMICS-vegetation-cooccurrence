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
#' @param fold_ids
#' Optional positive integer fold IDs to retain. `NULL` keeps all folds.
#' @param work_checkpoint_file
#' Optional `.qs` file that persists each completed candidate-fold result.
#' @param calibration_stage
#' Character label used in progress messages and checkpoint provenance.
#' @param seed,device
#' Deterministic seed and fitting device.
#' @param candidate_fit_function,predict_function,score_function
#' Injectable fitting, prediction, and scoring backends.
#' @param verbose
#' Logical. If `TRUE`, progress is printed to the console.
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
    fold_ids = NULL,
    work_checkpoint_file = NULL,
    calibration_stage = "calibration",
    seed = 900723L,
    device = "gpu",
    candidate_fit_function = fit_sjsdm_cross_validation_candidate,
    predict_function = predict_sjsdm_probability_matrix,
    score_function = score_sjsdm_joint_tuning_predictions,
    verbose = TRUE) {
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
    base::is.null(work_checkpoint_file) ||
      (
        base::is.character(work_checkpoint_file) &&
          base::length(work_checkpoint_file) == 1L &&
          !base::is.na(work_checkpoint_file) &&
          base::nzchar(work_checkpoint_file)
      ),
    base::is.character(calibration_stage),
    base::length(calibration_stage) == 1L,
    !base::is.na(calibration_stage),
    base::nzchar(calibration_stage),
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    !base::is.na(verbose),
    msg = "Calibration rung inputs are incomplete."
  )

  repeat_ids <-
    base::as.integer(repeat_ids)
  if (
    !base::is.null(fold_ids)
  ) {
    assertthat::assert_that(
      base::is.numeric(fold_ids),
      base::length(fold_ids) > 0L,
      base::all(base::is.finite(fold_ids)),
      base::all(fold_ids > 0L),
      base::all(fold_ids == base::as.integer(fold_ids)),
      msg = "fold_ids must contain positive integers or be NULL."
    )
    fold_ids <-
      base::as.integer(fold_ids)
  }
  list_records <-
    list_prepared_folds |>
    purrr::keep(
      ~ .x[["list_fold_context"]][["repeat_id"]] %in% repeat_ids &&
        (
          base::is.null(fold_ids) ||
            .x[["list_fold_context"]][["fold_id"]] %in% fold_ids
        )
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
    ) |>
    dplyr::mutate(
      candidate_id = data_candidates[["candidate_id"]][
        .data[["candidate_row"]]
      ],
      work_key = stringr::str_c(
        .data[["fold_key"]],
        .data[["candidate_id"]],
        sep = "__"
      )
    )

  work_checkpoint_signature <-
    digest::digest(
      base::list(
        work_checkpoint_contract_version =
          "sjsdm_cv_calibration_work_v1",
        data_candidates = data_candidates,
        list_records = list_records,
        data_budget = data_budget,
        formula = stringr::str_c(
          base::deparse(sel_abiotic_formula),
          collapse = ""
        ),
        config_budget = config_budget,
        repeat_ids = repeat_ids,
        fold_ids = fold_ids,
        seed = seed,
        device = device,
        calibration_stage = calibration_stage
      )
    )
  list_work_checkpoint <-
    if (
      !base::is.null(work_checkpoint_file) &&
        base::file.exists(work_checkpoint_file)
    ) {
      qs2::qs_read(work_checkpoint_file)
    } else {
      base::list(
        work_checkpoint_contract_version =
          "sjsdm_cv_calibration_work_v1",
        work_checkpoint_signature = work_checkpoint_signature,
        list_results = base::list()
      )
    }
  assertthat::assert_that(
    base::identical(
      list_work_checkpoint[["work_checkpoint_signature"]],
      work_checkpoint_signature
    ),
    msg = stringr::str_c(
      "The candidate-fit checkpoint belongs to a different",
      "calibration rung.",
      sep = " "
    )
  )
  list_results <-
    list_work_checkpoint[["list_results"]]

  for (
    work_index in base::seq_len(base::nrow(data_work))
  ) {
    work_key <-
      data_work[["work_key"]][[work_index]]
    if (
      !base::is.null(list_results[[work_key]])
    ) {
      next
    }

    fold_key <-
      data_work[["fold_key"]][[work_index]]
    candidate_row <-
      data_work[["candidate_row"]][[work_index]]
    candidate_id <-
      data_work[["candidate_id"]][[work_index]]
    list_record <-
      list_records[[fold_key]]
    list_context <-
      list_record[["list_fold_context"]]
    data_candidate <-
      data_candidates[candidate_row, , drop = FALSE]
    n_completed_before <-
      base::length(list_results)

    if (
      verbose
    ) {
      cli::cli_inform(
        stringr::str_glue(
          "Calibration {calibration_stage}: starting fit ",
          "{n_completed_before + 1L}/{base::nrow(data_work)}; ",
          "budget={data_budget[['n_iter']][[1L]]}, ",
          "repeat={list_context[['repeat_id']]}, ",
          "fold={list_context[['fold_id']]}, ",
          "candidate={candidate_id}."
        )
      )
    }

    list_results[[work_key]] <-
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

    if (
      !base::is.null(work_checkpoint_file)
    ) {
      fs::dir_create(fs::path_dir(work_checkpoint_file))
      qs2::qs_save(
        base::list(
          work_checkpoint_contract_version =
            "sjsdm_cv_calibration_work_v1",
          work_checkpoint_signature = work_checkpoint_signature,
          list_results = list_results
        ),
        work_checkpoint_file
      )
    }

    if (
      verbose
    ) {
      cli::cli_inform(
        stringr::str_glue(
          "Calibration {calibration_stage}: completed fit ",
          "{base::length(list_results)}/{base::nrow(data_work)}; ",
          "repeat={list_context[['repeat_id']]}, ",
          "fold={list_context[['fold_id']]}, ",
          "candidate={candidate_id}."
        )
      )
    }
  }

  list_results_ordered <-
    list_results[data_work[["work_key"]]]

  data_benchmark <-
    list_results_ordered |>
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
    list_results_ordered |>
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

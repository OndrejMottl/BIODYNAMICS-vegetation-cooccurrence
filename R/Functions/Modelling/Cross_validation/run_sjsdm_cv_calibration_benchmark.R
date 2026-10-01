#' @title Run an Adaptive sjSDM CV Budget Calibration
#' @description
#' Screens all candidates on three folds at a reduced sampling budget. After
#' each stable adjacent-rung pair, it confirms the winner and runner-up on all
#' five folds of repeats one and two at the production sampling budget.
#' @param data_candidates,list_prepared_folds,sel_abiotic_formula
#' Calibration model inputs.
#' @param config_sjsdm_cv_fitting
#' Validated structural CV fitting configuration.
#' @param data_ladder
#' Ordered budget ladder from [build_sjsdm_cv_calibration_ladder()].
#' @param screening_fold_ids,confirmation_fold_ids
#' Deterministic fold IDs used for screening and confirmation.
#' @param confirmation_sampling
#' Production sampling budget used for confirmation.
#' @param n_confirmation_candidates
#' Number of leading screening candidates retained for confirmation.
#' @param repeat_confirmation_loss_tolerance
#' Maximum relative loss gap allowed above the repeat-two winner.
#' @param checkpoint_file
#' Optional `.qs` path used to resume completed rungs after interruption.
#' @param verbose
#' Logical. If `TRUE`, progress is printed to the console.
#' @param rung_function
#' Injectable rung executor for deterministic orchestration tests.
#' @param ...
#' Additional arguments passed to [run_sjsdm_cv_calibration_rung()].
#' @return
#' Calibration status, accepted budget when available, benchmark evidence, and
#' attempt-level provenance accumulated before stopping.
#' @export
run_sjsdm_cv_calibration_benchmark <- function(
    data_candidates = NULL,
    list_prepared_folds = NULL,
    sel_abiotic_formula = NULL,
    config_sjsdm_cv_fitting = NULL,
    data_ladder = build_sjsdm_cv_calibration_ladder(),
    screening_fold_ids = 1:3,
    confirmation_fold_ids = 1:5,
    confirmation_sampling = 200L,
    n_confirmation_candidates = 2L,
    repeat_confirmation_loss_tolerance = 0.02,
    checkpoint_file = NULL,
    rung_function = run_sjsdm_cv_calibration_rung,
    verbose = TRUE,
    ...) {
  assertthat::assert_that(
    base::is.data.frame(data_ladder),
    base::nrow(data_ladder) >= 2L,
    base::identical(
      data_ladder[["budget_order"]],
      base::seq_len(base::nrow(data_ladder))
    ),
    msg = "Calibration ladder must contain consecutive ordered rungs."
  )
  assertthat::assert_that(
    base::is.function(rung_function),
    msg = "rung_function must be a function."
  )
  assertthat::assert_that(
    base::is.data.frame(data_candidates),
    "candidate_id" %in% base::colnames(data_candidates),
    base::length(screening_fold_ids) > 0L,
    base::length(confirmation_fold_ids) > 0L,
    base::is.numeric(confirmation_sampling),
    base::length(confirmation_sampling) == 1L,
    base::is.finite(confirmation_sampling),
    confirmation_sampling > 0L,
    base::is.numeric(n_confirmation_candidates),
    base::length(n_confirmation_candidates) == 1L,
    base::is.finite(n_confirmation_candidates),
    n_confirmation_candidates > 0L,
    base::is.numeric(repeat_confirmation_loss_tolerance),
    base::length(repeat_confirmation_loss_tolerance) == 1L,
    base::is.finite(repeat_confirmation_loss_tolerance),
    repeat_confirmation_loss_tolerance >= 0,
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    !base::is.na(verbose),
    msg = "Adaptive calibration settings are incomplete."
  )

  screening_fold_ids <-
    base::sort(base::unique(base::as.integer(screening_fold_ids)))
  confirmation_fold_ids <-
    base::sort(base::unique(base::as.integer(confirmation_fold_ids)))
  confirmation_sampling <-
    base::as.integer(confirmation_sampling)
  n_confirmation_candidates <-
    base::as.integer(n_confirmation_candidates)
  list_checkpoint_signature_payload <-
    base::list(
      data_ladder = data_ladder,
      data_candidates = data_candidates,
      list_prepared_folds = list_prepared_folds,
      sel_abiotic_formula = stringr::str_c(
        base::deparse(sel_abiotic_formula),
        collapse = ""
      ),
      config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
      screening_fold_ids = screening_fold_ids,
      confirmation_fold_ids = confirmation_fold_ids,
      confirmation_sampling = confirmation_sampling,
      n_confirmation_candidates = n_confirmation_candidates
    )
  checkpoint_signature_v2 <-
    digest::digest(list_checkpoint_signature_payload)
  checkpoint_signature_v3 <-
    digest::digest(
      base::list(
        checkpoint_contract_version =
          "sjsdm_cv_adaptive_calibration_checkpoint_v3",
        signature_payload = list_checkpoint_signature_payload,
        repeat_confirmation_loss_tolerance =
          repeat_confirmation_loss_tolerance
      )
    )
  checkpoint_signature_v3_previous_policy <-
    digest::digest(
      base::list(
        checkpoint_contract_version =
          "sjsdm_cv_adaptive_calibration_checkpoint_v3",
        signature_payload = list_checkpoint_signature_payload,
        repeat_confirmation_loss_tolerance = 0.01
      )
    )
  list_checkpoint_loaded <-
    if (
      !base::is.null(checkpoint_file) &&
        base::file.exists(checkpoint_file)
    ) {
      qs2::qs_read(checkpoint_file)
    } else {
      base::list(
        checkpoint_contract_version =
          "sjsdm_cv_adaptive_calibration_checkpoint_v3",
        checkpoint_signature = checkpoint_signature_v3,
        list_screening = base::list(),
        list_confirmation = base::list(),
        rejected_confirmation_orders = base::integer(),
        accepted_budget = NULL
      )
    }
  flag_current_checkpoint <-
    base::identical(
      list_checkpoint_loaded[["checkpoint_signature"]],
      checkpoint_signature_v3
    )
  flag_compatible_v2_checkpoint <-
    base::identical(
      list_checkpoint_loaded[["checkpoint_signature"]],
      checkpoint_signature_v2
    )
  flag_compatible_v3_policy_checkpoint <-
    base::identical(
      list_checkpoint_loaded[["checkpoint_contract_version"]],
      "sjsdm_cv_adaptive_calibration_checkpoint_v3"
    ) &&
    base::identical(
      list_checkpoint_loaded[["checkpoint_signature"]],
      checkpoint_signature_v3_previous_policy
    )
  assertthat::assert_that(
    flag_current_checkpoint ||
      flag_compatible_v2_checkpoint ||
      flag_compatible_v3_policy_checkpoint,
    msg = stringr::str_c(
      "The calibration checkpoint belongs to a different adaptive",
      "calibration contract. Remove that checkpoint before restarting.",
      sep = " "
    )
  )
  list_checkpoint <-
    if (
      flag_compatible_v2_checkpoint ||
        flag_compatible_v3_policy_checkpoint
    ) {
      if (
        verbose
      ) {
        checkpoint_source <-
          if (
            flag_compatible_v2_checkpoint
          ) {
            "version-2"
          } else {
            "version-3 prior-policy"
          }
        cli::cli_inform(
          stringr::str_glue(
            "Reusing {checkpoint_source} calibration fits and ",
            "re-evaluating policy-dependent confirmation decisions."
          )
        )
      }
      migration_status <-
        if (
          flag_compatible_v2_checkpoint
        ) {
          "reused_v2_fit_evidence"
        } else {
          "reused_v3_policy_fit_evidence"
        }
      base::list(
        checkpoint_contract_version =
          "sjsdm_cv_adaptive_calibration_checkpoint_v3",
        checkpoint_signature = checkpoint_signature_v3,
        list_screening = list_checkpoint_loaded[["list_screening"]],
        list_confirmation =
          list_checkpoint_loaded[["list_confirmation"]],
        rejected_confirmation_orders = base::integer(),
        accepted_budget = NULL,
        checkpoint_migration_status = migration_status
      )
    } else {
      list_checkpoint_loaded
    }

  list_screening <-
    list_checkpoint[["list_screening"]]
  list_confirmation <-
    list_checkpoint[["list_confirmation"]]
  vec_rejected_confirmation_orders <-
    list_checkpoint[["rejected_confirmation_orders"]]
  accepted_budget <-
    list_checkpoint[["accepted_budget"]]
  checkpoint_migration_status <-
    purrr::pluck(
      list_checkpoint,
      "checkpoint_migration_status",
      .default = NA_character_
    )

  for (
    budget_index in base::seq_len(base::nrow(data_ladder))
  ) {
    if (
      !base::is.null(accepted_budget)
    ) {
      break
    }
    if (
      base::length(list_screening) < budget_index ||
        base::is.null(list_screening[[budget_index]])
    ) {
      list_screening[[budget_index]] <-
        rung_function(
          data_candidates = data_candidates,
          list_prepared_folds = list_prepared_folds,
          data_budget = data_ladder[budget_index, , drop = FALSE],
          sel_abiotic_formula = sel_abiotic_formula,
          config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
          repeat_ids = 1L,
          fold_ids = screening_fold_ids,
          work_checkpoint_file = if (
            base::is.null(checkpoint_file)
          ) {
            NULL
          } else {
            fs::path(
              fs::path_dir(checkpoint_file),
              stringr::str_glue(
                "calibration_screening_{budget_index}_work.qs"
              )
            )
          },
          calibration_stage = "screening",
          verbose = verbose,
          ...
        )
      list_screening[[budget_index]][["data_benchmark"]] <-
        list_screening[[budget_index]][["data_benchmark"]] |>
        dplyr::mutate(calibration_stage = "screening", .before = 1L)
      list_screening[[budget_index]][["data_fit_attempts"]] <-
        list_screening[[budget_index]][["data_fit_attempts"]] |>
        dplyr::mutate(calibration_stage = "screening", .before = 1L)
      if (
        !base::is.null(checkpoint_file)
      ) {
        fs::dir_create(fs::path_dir(checkpoint_file))
        qs2::qs_save(
          base::list(
            checkpoint_contract_version =
              "sjsdm_cv_adaptive_calibration_checkpoint_v3",
            checkpoint_signature = checkpoint_signature_v3,
            list_screening = list_screening,
            list_confirmation = list_confirmation,
            rejected_confirmation_orders =
              vec_rejected_confirmation_orders,
            accepted_budget = accepted_budget,
            checkpoint_migration_status =
              checkpoint_migration_status
          ),
          checkpoint_file
        )
      }
    }

    if (
      budget_index < 2L
    ) {
      next
    }

    data_repeat_one <-
      list_screening |>
      purrr::compact() |>
      purrr::map("data_benchmark") |>
      purrr::list_rbind()
    if (
      base::length(vec_rejected_confirmation_orders) > 0L
    ) {
      data_repeat_one <-
        data_repeat_one |>
        dplyr::filter(
          .data[["budget_order"]] >
            base::max(vec_rejected_confirmation_orders)
        )
    }

    provisional_budget <-
      base::tryCatch(
        select_sjsdm_cv_calibration_budget(
          data_benchmark = data_repeat_one,
          n_folds_expected = base::length(screening_fold_ids),
          require_repeat_two = FALSE
        ),
        error = function(error_condition) NULL
      )

    if (
      base::is.null(provisional_budget)
    ) {
      next
    }

    confirmation_index <-
      provisional_budget[["budget_order"]][[1L]]
    if (
      base::length(list_confirmation) < confirmation_index ||
        base::is.null(list_confirmation[[confirmation_index]])
    ) {
      data_confirmation_candidates <-
        data_repeat_one |>
        dplyr::filter(
          .data[["budget_order"]] == confirmation_index,
          .data[["repeat_id"]] == 1L,
          .data[["converged"]],
          base::is.finite(.data[["normalized_loss"]])
        ) |>
        dplyr::group_by(.data[["candidate_id"]]) |>
        dplyr::summarise(
          candidate_loss = base::mean(.data[["normalized_loss"]]),
          .groups = "drop"
        ) |>
        dplyr::arrange(
          .data[["candidate_loss"]],
          .data[["candidate_id"]]
        ) |>
        dplyr::slice_head(n = n_confirmation_candidates) |>
        dplyr::select("candidate_id") |>
        dplyr::inner_join(data_candidates, by = "candidate_id")
      data_confirmation_budget <-
        data_ladder[confirmation_index, , drop = FALSE]
      data_confirmation_budget[["n_sampling"]] <-
        base::max(
          confirmation_sampling,
          data_confirmation_budget[["n_sampling"]]
        )
      list_confirmation[[confirmation_index]] <-
        rung_function(
          data_candidates = data_confirmation_candidates,
          list_prepared_folds = list_prepared_folds,
          data_budget = data_confirmation_budget,
          sel_abiotic_formula = sel_abiotic_formula,
          config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
          repeat_ids = 1:2,
          fold_ids = confirmation_fold_ids,
          work_checkpoint_file = if (
            base::is.null(checkpoint_file)
          ) {
            NULL
          } else {
            fs::path(
              fs::path_dir(checkpoint_file),
              stringr::str_glue(
                "calibration_confirmation_{confirmation_index}_work.qs"
              )
            )
          },
          calibration_stage = "confirmation",
          verbose = verbose,
          ...
        )
      list_confirmation[[confirmation_index]][["data_benchmark"]] <-
        list_confirmation[[confirmation_index]][["data_benchmark"]] |>
        dplyr::mutate(calibration_stage = "confirmation", .before = 1L)
      list_confirmation[[confirmation_index]][["data_fit_attempts"]] <-
        list_confirmation[[confirmation_index]][["data_fit_attempts"]] |>
        dplyr::mutate(calibration_stage = "confirmation", .before = 1L)
    }

    data_confirmation <-
      list_confirmation[[confirmation_index]][["data_benchmark"]]
    data_confirmation_summary <-
      data_confirmation |>
      dplyr::group_by(.data[["repeat_id"]], .data[["candidate_id"]]) |>
      dplyr::summarise(
        n_folds = dplyr::n_distinct(.data[["fold_id"]]),
        all_converged = base::all(.data[["converged"]] %in% TRUE),
        all_losses_finite = base::all(
          base::is.finite(.data[["normalized_loss"]])
        ),
        candidate_loss = base::mean(.data[["normalized_loss"]]),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        candidate_complete =
          .data[["n_folds"]] == base::length(confirmation_fold_ids) &
          .data[["all_converged"]] &
          .data[["all_losses_finite"]]
      )
    n_confirmation_candidates_actual <-
      dplyr::n_distinct(data_confirmation[["candidate_id"]])
    flag_confirmation_complete <-
      base::nrow(data_confirmation_summary) ==
        2L * n_confirmation_candidates_actual &&
      base::all(data_confirmation_summary[["candidate_complete"]])
    data_repeat_confirmation <-
      evaluate_sjsdm_cv_repeat_confirmation(
        data_candidate_summary = data_confirmation_summary,
        provisional_candidate_id =
          provisional_budget[["candidate_id"]][[1L]],
        relative_loss_tolerance =
          repeat_confirmation_loss_tolerance
      )

    if (
      flag_confirmation_complete &&
        data_repeat_confirmation[["repeat_two_confirmed"]][[1L]]
    ) {
      accepted_budget <-
        provisional_budget |>
        dplyr::select(-dplyr::starts_with("repeat_two_")) |>
        dplyr::bind_cols(data_repeat_confirmation) |>
        dplyr::mutate(
          screening_n_sampling = .data[["n_sampling"]],
          n_sampling = base::max(
            confirmation_sampling,
            .data[["n_sampling"]]
          ),
          screening_n_folds = base::length(screening_fold_ids),
          confirmation_n_folds =
            base::length(confirmation_fold_ids),
          confirmation_candidate_count =
            n_confirmation_candidates_actual
        )
    } else {
      vec_rejected_confirmation_orders <-
        base::c(
          vec_rejected_confirmation_orders,
          confirmation_index
        )
    }

    if (
      !base::is.null(checkpoint_file)
    ) {
      fs::dir_create(fs::path_dir(checkpoint_file))
      qs2::qs_save(
        base::list(
          checkpoint_contract_version =
            "sjsdm_cv_adaptive_calibration_checkpoint_v3",
          checkpoint_signature = checkpoint_signature_v3,
          list_screening = list_screening,
          list_confirmation = list_confirmation,
          rejected_confirmation_orders =
            vec_rejected_confirmation_orders,
          accepted_budget = accepted_budget,
          checkpoint_migration_status =
            checkpoint_migration_status
        ),
        checkpoint_file
      )
    }
    if (
      !base::is.null(accepted_budget)
    ) {
      break
    }
  }

  list_all <-
    base::c(list_screening, list_confirmation) |>
    purrr::compact()

  res <-
    base::list(
      calibration_status = if (
        base::is.null(accepted_budget)
      ) {
        "no_accepted_budget"
      } else {
        "accepted"
      },
      data_accepted_budget = if (
        base::is.null(accepted_budget)
      ) {
        tibble::tibble()
      } else {
        accepted_budget
      },
      data_benchmark = list_all |>
        purrr::map("data_benchmark") |>
        purrr::list_rbind(),
      data_fit_attempts = list_all |>
        purrr::map("data_fit_attempts") |>
        purrr::compact() |>
        purrr::list_rbind(),
      checkpoint_migration_status = checkpoint_migration_status
    )

  return(res)
}

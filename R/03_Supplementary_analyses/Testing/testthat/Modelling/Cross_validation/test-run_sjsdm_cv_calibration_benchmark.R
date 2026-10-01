testthat::test_that(
  "run_sjsdm_cv_calibration_benchmark() stops at first stable budget",
  {
    rung_function <- function(
        data_candidates,
        list_prepared_folds,
        data_budget,
        sel_abiotic_formula,
        config_sjsdm_cv_fitting,
        repeat_ids,
        fold_ids,
        ...) {
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = fold_ids,
          candidate_id = data_candidates[["candidate_id"]]
        ) |>
        dplyr::mutate(
          budget_order = data_budget[["budget_order"]][[1L]],
          n_iter = data_budget[["n_iter"]][[1L]],
          n_sampling = data_budget[["n_sampling"]][[1L]],
          converged = .data[["budget_order"]] >= 2L,
          normalized_loss = dplyr::if_else(
            .data[["candidate_id"]] == "candidate_1",
            0.2 + .data[["budget_order"]] * 0.0005,
            0.4 + .data[["budget_order"]] * 0.0005
          )
        )

      base::list(
        data_benchmark = data_benchmark,
        data_fit_attempts = tibble::tibble(
          budget_order = data_budget[["budget_order"]][[1L]],
          repeat_id = repeat_ids
        )
      )
    }

    res <-
      run_sjsdm_cv_calibration_benchmark(
        data_candidates = tibble::tibble(
          candidate_id = base::c("candidate_1", "candidate_2")
        ),
        list_prepared_folds = base::list(value = TRUE),
        sel_abiotic_formula = ~ x,
        config_sjsdm_cv_fitting = base::list(value = TRUE),
        data_ladder = build_sjsdm_cv_calibration_ladder()[1:4, ],
        rung_function = rung_function
      )

    testthat::expect_equal(res[["calibration_status"]], "accepted")
    testthat::expect_equal(
      res[["data_accepted_budget"]][["n_iter_initial"]],
      1000L
    )
    testthat::expect_equal(
      base::sort(base::unique(res[["data_benchmark"]][["budget_order"]])),
      1:3
    )
    data_repeat_two <-
      res[["data_benchmark"]] |>
      dplyr::filter(.data[["repeat_id"]] == 2L)
    testthat::expect_equal(
      base::unique(data_repeat_two[["budget_order"]]),
      2L
    )
    testthat::expect_equal(
      res[["data_accepted_budget"]][["n_sampling"]],
      200L
    )
    testthat::expect_setequal(
      res[["data_benchmark"]][["calibration_stage"]],
      base::c("screening", "confirmation")
    )
  }
)

testthat::test_that(
  "run_sjsdm_cv_calibration_benchmark() resumes completed rungs",
  {
    file_checkpoint <-
      tempfile(fileext = ".qs")
    on.exit(base::unlink(file_checkpoint), add = TRUE)
    state <-
      new.env(parent = emptyenv())
    state[["calls"]] <-
      0L
    state[["fail_second_call"]] <-
      TRUE

    rung_function <- function(
        data_candidates,
        list_prepared_folds,
        data_budget,
        sel_abiotic_formula,
        config_sjsdm_cv_fitting,
        repeat_ids,
        fold_ids,
        ...) {
      state[["calls"]] <-
        state[["calls"]] + 1L
      if (
        state[["fail_second_call"]] && state[["calls"]] == 2L
      ) {
        base::stop("simulated interruption")
      }
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = fold_ids,
          candidate_id = data_candidates[["candidate_id"]]
        ) |>
        dplyr::mutate(
          budget_order = data_budget[["budget_order"]][[1L]],
          n_iter = data_budget[["n_iter"]][[1L]],
          n_sampling = data_budget[["n_sampling"]][[1L]],
          converged = TRUE,
          normalized_loss = dplyr::if_else(
            .data[["candidate_id"]] == "candidate_1",
            0.2,
            0.4
          )
        )
      base::list(
        data_benchmark = data_benchmark,
        data_fit_attempts = tibble::tibble(
          budget_order = data_budget[["budget_order"]][[1L]],
          repeat_id = repeat_ids
        )
      )
    }
    list_arguments <-
      base::list(
        data_candidates = tibble::tibble(
          candidate_id = base::c("candidate_1", "candidate_2")
        ),
        list_prepared_folds = base::list(value = TRUE),
        sel_abiotic_formula = ~ x,
        config_sjsdm_cv_fitting = base::list(value = TRUE),
        data_ladder = build_sjsdm_cv_calibration_ladder()[1:3, ],
        checkpoint_file = file_checkpoint,
        rung_function = rung_function
      )

    testthat::expect_error(
      rlang::exec(
        run_sjsdm_cv_calibration_benchmark,
        !!!list_arguments
      ),
      regexp = "simulated interruption"
    )
    testthat::expect_true(base::file.exists(file_checkpoint))
    state[["fail_second_call"]] <-
      FALSE
    res <-
      rlang::exec(
        run_sjsdm_cv_calibration_benchmark,
        !!!list_arguments
      )

    testthat::expect_equal(res[["calibration_status"]], "accepted")
    testthat::expect_equal(state[["calls"]], 4L)
    list_changed_arguments <-
      list_arguments
    list_changed_arguments[["list_prepared_folds"]] <-
      base::list(value = FALSE)
    testthat::expect_error(
      rlang::exec(
        run_sjsdm_cv_calibration_benchmark,
        !!!list_changed_arguments
      ),
      regexp = "different adaptive calibration contract"
    )
  }
)

testthat::test_that(
  "run_sjsdm_cv_calibration_benchmark() advances after failed confirmation",
  {
    rung_function <- function(
        data_candidates,
        list_prepared_folds,
        data_budget,
        sel_abiotic_formula,
        config_sjsdm_cv_fitting,
        repeat_ids,
        fold_ids,
        ...) {
      budget_order <-
        data_budget[["budget_order"]][[1L]]
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = fold_ids,
          candidate_id = data_candidates[["candidate_id"]]
        ) |>
        dplyr::mutate(
          budget_order = budget_order,
          n_iter = data_budget[["n_iter"]][[1L]],
          n_sampling = data_budget[["n_sampling"]][[1L]],
          converged = TRUE,
          normalized_loss = dplyr::case_when(
            .data[["repeat_id"]] == 2L & budget_order == 1L &
              .data[["candidate_id"]] == "candidate_2" ~ 0.1,
            .data[["candidate_id"]] == "candidate_1" ~ 0.2,
            TRUE ~ 0.4
          )
        )
      base::list(
        data_benchmark = data_benchmark,
        data_fit_attempts = tibble::tibble(
          budget_order = budget_order,
          repeat_id = repeat_ids
        )
      )
    }

    res <-
      run_sjsdm_cv_calibration_benchmark(
        data_candidates = tibble::tibble(
          candidate_id = base::c("candidate_1", "candidate_2")
        ),
        list_prepared_folds = base::list(value = TRUE),
        sel_abiotic_formula = ~ x,
        config_sjsdm_cv_fitting = base::list(value = TRUE),
        data_ladder = build_sjsdm_cv_calibration_ladder()[1:4, ],
        rung_function = rung_function
      )

    testthat::expect_equal(
      res[["data_accepted_budget"]][["budget_order"]],
      2L
    )
    data_repeat_two <-
      res[["data_benchmark"]] |>
      dplyr::filter(.data[["repeat_id"]] == 2L)
    testthat::expect_equal(
      base::sort(base::unique(data_repeat_two[["budget_order"]])),
      1:2
    )
  }
)

testthat::test_that(
  "run_sjsdm_cv_calibration_benchmark() accepts a repeat-two near tie",
  {
    rung_function <- function(
        data_candidates,
        list_prepared_folds,
        data_budget,
        sel_abiotic_formula,
        config_sjsdm_cv_fitting,
        repeat_ids,
        fold_ids,
        ...) {
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = fold_ids,
          candidate_id = data_candidates[["candidate_id"]]
        ) |>
        dplyr::mutate(
          budget_order = data_budget[["budget_order"]][[1L]],
          n_iter = data_budget[["n_iter"]][[1L]],
          n_sampling = data_budget[["n_sampling"]][[1L]],
          converged = TRUE,
          normalized_loss = dplyr::case_when(
            .data[["repeat_id"]] == 1L &
              .data[["candidate_id"]] == "candidate_002" ~ 0.1,
            .data[["repeat_id"]] == 1L ~ 0.101,
            .data[["candidate_id"]] == "candidate_001" ~ 0.1,
            .default = 0.1015
          ) + .data[["budget_order"]] / 100000
        )
      base::list(
        data_benchmark = data_benchmark,
        data_fit_attempts = tibble::tibble()
      )
    }

    res <-
      run_sjsdm_cv_calibration_benchmark(
        data_candidates = tibble::tibble(
          candidate_id = base::c("candidate_001", "candidate_002")
        ),
        list_prepared_folds = base::list(value = TRUE),
        sel_abiotic_formula = ~ x,
        config_sjsdm_cv_fitting = base::list(value = TRUE),
        data_ladder = build_sjsdm_cv_calibration_ladder()[1:2, ],
        rung_function = rung_function,
        verbose = FALSE
      )

    testthat::expect_equal(res[["calibration_status"]], "accepted")
    testthat::expect_equal(
      res[["data_accepted_budget"]][["n_iter_initial"]],
      500L
    )
    testthat::expect_false(
      res[["data_accepted_budget"]][["repeat_two_exact_winner"]]
    )
    testthat::expect_true(
      res[["data_accepted_budget"]][[
        "repeat_two_practically_equivalent"
      ]]
    )
  }
)

testthat::test_that(
  "run_sjsdm_cv_calibration_benchmark() reuses version-two fit evidence",
  {
    file_checkpoint <-
      tempfile(fileext = ".qs")
    on.exit(base::unlink(file_checkpoint), add = TRUE)
    state <-
      new.env(parent = base::emptyenv())
    state[["calls"]] <-
      0L
    data_candidates <-
      tibble::tibble(
        candidate_id = base::c("candidate_001", "candidate_002")
      )
    list_prepared_folds <-
      base::list(value = TRUE)
    config_sjsdm_cv_fitting <-
      base::list(value = TRUE)
    data_ladder <-
      build_sjsdm_cv_calibration_ladder()[1:2, ]
    rung_function <- function(
        data_candidates,
        list_prepared_folds,
        data_budget,
        sel_abiotic_formula,
        config_sjsdm_cv_fitting,
        repeat_ids,
        fold_ids,
        ...) {
      state[["calls"]] <-
        state[["calls"]] + 1L
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = fold_ids,
          candidate_id = data_candidates[["candidate_id"]]
        ) |>
        dplyr::mutate(
          budget_order = data_budget[["budget_order"]][[1L]],
          n_iter = data_budget[["n_iter"]][[1L]],
          n_sampling = data_budget[["n_sampling"]][[1L]],
          converged = TRUE,
          normalized_loss = dplyr::if_else(
            .data[["candidate_id"]] == "candidate_001",
            0.2,
            0.4
          )
        )
      base::list(
        data_benchmark = data_benchmark,
        data_fit_attempts = tibble::tibble()
      )
    }
    list_arguments <-
      base::list(
        data_candidates = data_candidates,
        list_prepared_folds = list_prepared_folds,
        sel_abiotic_formula = ~ x,
        config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
        data_ladder = data_ladder,
        checkpoint_file = file_checkpoint,
        rung_function = rung_function,
        verbose = FALSE
      )

    res_initial <-
      rlang::exec(
        run_sjsdm_cv_calibration_benchmark,
        !!!list_arguments
      )
    n_initial_calls <-
      state[["calls"]]
    list_checkpoint <-
      qs2::qs_read(file_checkpoint)
    list_checkpoint[["checkpoint_contract_version"]] <-
      "sjsdm_cv_adaptive_calibration_checkpoint_v2"
    list_checkpoint[["checkpoint_signature"]] <-
      digest::digest(
        base::list(
          data_ladder = data_ladder,
          data_candidates = data_candidates,
          list_prepared_folds = list_prepared_folds,
          sel_abiotic_formula = "~x",
          config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
          screening_fold_ids = 1:3,
          confirmation_fold_ids = 1:5,
          confirmation_sampling = 200L,
          n_confirmation_candidates = 2L
        )
      )
    list_checkpoint[["accepted_budget"]] <-
      NULL
    list_checkpoint[["rejected_confirmation_orders"]] <-
      1L
    qs2::qs_save(list_checkpoint, file_checkpoint)

    res_migrated <-
      rlang::exec(
        run_sjsdm_cv_calibration_benchmark,
        !!!list_arguments
      )

    testthat::expect_equal(res_initial[["calibration_status"]], "accepted")
    testthat::expect_equal(res_migrated[["calibration_status"]], "accepted")
    testthat::expect_equal(state[["calls"]], n_initial_calls)
    testthat::expect_equal(
      res_migrated[["checkpoint_migration_status"]],
      "reused_v2_fit_evidence"
    )

    list_checkpoint <-
      qs2::qs_read(file_checkpoint)
    list_checkpoint[["checkpoint_signature"]] <-
      digest::digest(
        base::list(
          checkpoint_contract_version =
            "sjsdm_cv_adaptive_calibration_checkpoint_v3",
          signature_payload = base::list(
            data_ladder = data_ladder,
            data_candidates = data_candidates,
            list_prepared_folds = list_prepared_folds,
            sel_abiotic_formula = "~x",
            config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
            screening_fold_ids = 1:3,
            confirmation_fold_ids = 1:5,
            confirmation_sampling = 200L,
            n_confirmation_candidates = 2L
          ),
          repeat_confirmation_loss_tolerance = 0.01
        )
      )
    list_checkpoint[["accepted_budget"]] <-
      NULL
    list_checkpoint[["rejected_confirmation_orders"]] <-
      1L
    qs2::qs_save(list_checkpoint, file_checkpoint)

    res_policy_migrated <-
      rlang::exec(
        run_sjsdm_cv_calibration_benchmark,
        !!!list_arguments
      )

    testthat::expect_equal(
      res_policy_migrated[["calibration_status"]],
      "accepted"
    )
    testthat::expect_equal(state[["calls"]], n_initial_calls)
    testthat::expect_equal(
      res_policy_migrated[["checkpoint_migration_status"]],
      "reused_v3_policy_fit_evidence"
    )
  }
)

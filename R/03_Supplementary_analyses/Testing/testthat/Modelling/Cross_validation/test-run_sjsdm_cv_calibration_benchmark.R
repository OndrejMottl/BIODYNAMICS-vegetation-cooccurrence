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
        ...) {
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = 1:5,
          candidate_id = base::c("candidate_1", "candidate_2")
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
        data_candidates = tibble::tibble(value = 1L),
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
        ...) {
      budget_order <-
        data_budget[["budget_order"]][[1L]]
      data_benchmark <-
        tidyr::crossing(
          repeat_id = repeat_ids,
          fold_id = 1:5,
          candidate_id = base::c("candidate_1", "candidate_2")
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
        data_candidates = tibble::tibble(value = 1L),
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

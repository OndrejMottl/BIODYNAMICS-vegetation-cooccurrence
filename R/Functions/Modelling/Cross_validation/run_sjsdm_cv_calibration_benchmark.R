#' @title Run an Adaptive sjSDM CV Budget Calibration
#' @description
#' Executes repeat one rung by rung on cached folds. After each adjacent pair,
#' it runs repeat two at the smaller budget and stops at the first budget that
#' satisfies the registered convergence and stability criteria.
#' @param data_candidates,list_prepared_folds,sel_abiotic_formula
#' Calibration model inputs.
#' @param config_sjsdm_cv_fitting
#' Validated structural CV fitting configuration.
#' @param data_ladder
#' Ordered budget ladder from [build_sjsdm_cv_calibration_ladder()].
#' @param n_folds_expected
#' Required complete fold count. Defaults to five.
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
    n_folds_expected = 5L,
    rung_function = run_sjsdm_cv_calibration_rung,
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

  list_repeat_one <-
    base::list()
  list_repeat_two <-
    base::list()
  vec_rejected_confirmation_orders <-
    base::integer()
  accepted_budget <-
    NULL

  for (
    budget_index in base::seq_len(base::nrow(data_ladder))
  ) {
    list_repeat_one[[budget_index]] <-
      rung_function(
        data_candidates = data_candidates,
        list_prepared_folds = list_prepared_folds,
        data_budget = data_ladder[budget_index, , drop = FALSE],
        sel_abiotic_formula = sel_abiotic_formula,
        config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
        repeat_ids = 1L,
        ...
      )

    if (
      budget_index < 2L
    ) {
      next
    }

    data_repeat_one <-
      list_repeat_one |>
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
          n_folds_expected = n_folds_expected,
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
    list_repeat_two[[confirmation_index]] <-
      rung_function(
        data_candidates = data_candidates,
        list_prepared_folds = list_prepared_folds,
        data_budget = data_ladder[
          confirmation_index,
          ,
          drop = FALSE
        ],
        sel_abiotic_formula = sel_abiotic_formula,
        config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
        repeat_ids = 2L,
        ...
      )

    data_benchmark_current <-
      base::c(list_repeat_one, list_repeat_two) |>
      purrr::compact() |>
      purrr::map("data_benchmark") |>
      purrr::list_rbind()

    accepted_budget <-
      base::tryCatch(
        select_sjsdm_cv_calibration_budget(
          data_benchmark = data_benchmark_current,
          n_folds_expected = n_folds_expected
        ),
        error = function(error_condition) NULL
      )

    if (
      !base::is.null(accepted_budget)
    ) {
      break
    }
    vec_rejected_confirmation_orders <-
      base::c(
        vec_rejected_confirmation_orders,
        confirmation_index
      )
  }

  list_all <-
    base::c(list_repeat_one, list_repeat_two) |>
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
        purrr::list_rbind()
    )

  return(res)
}

#' @title Assign Accepted sjSDM CV Budgets to Production Units
#' @description
#' Assigns the most demanding accepted median/maximum representative budget to
#' ordinary units within each analysis-tier-continent-resolution group. A
#' benchmarked historical outlier or temporal profile keeps its own accepted
#' budget.
#' @param data_units
#' Complete calibration unit inventory.
#' @param data_accepted
#' Accepted representative budgets with unit keys, selection reasons, budget
#' order, iterations, and sampling.
#' @param cv_n_step_size,cv_n_early_stopping
#' Fixed CV optimizer values to publish; missing values are retained as typed
#' `NA` for CSV/config serialization.
#' @return
#' Unit-keyed production CV budget table.
#' @export
resolve_sjsdm_cv_calibration_budgets <- function(
    data_units = NULL,
    data_accepted = NULL,
    cv_n_step_size = NA_real_,
    cv_n_early_stopping = NA_integer_) {
  vec_unit_keys <-
    base::c(
      "analysis_id",
      "tier_id",
      "continent_id",
      "resolution_id",
      "scale_id"
    )
  vec_group_keys <-
    vec_unit_keys[1:4]
  vec_accepted_columns <-
    base::c(
      vec_unit_keys,
      "selection_reason",
      "budget_order",
      "n_iter_initial",
      "n_iter_max",
      "n_sampling"
    )

  assertthat::assert_that(
    base::is.data.frame(data_units),
    base::all(vec_unit_keys %in% base::colnames(data_units)),
    base::is.data.frame(data_accepted),
    base::all(vec_accepted_columns %in% base::colnames(data_accepted)),
    !base::any(base::duplicated(data_units[vec_unit_keys])),
    !base::any(base::duplicated(data_accepted[vec_unit_keys])),
    msg = "Calibration assignment inputs are incomplete or duplicated."
  )

  if (
    !"measured_seconds_per_fit" %in% base::colnames(data_accepted)
  ) {
    data_accepted[["measured_seconds_per_fit"]] <-
      NA_real_
  }
  if (
    !"measured_seconds_per_epoch" %in% base::colnames(data_accepted)
  ) {
    data_accepted[["measured_seconds_per_epoch"]] <-
      NA_real_
  }

  data_group_budgets <-
    data_accepted |>
    dplyr::filter(
      stringr::str_detect(
        .data[["selection_reason"]],
        "median_complexity|maximum_complexity"
      )
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(vec_group_keys))) |>
    dplyr::arrange(
      dplyr::desc(.data[["budget_order"]]),
      .data[["scale_id"]],
      .by_group = TRUE
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::ungroup() |>
    dplyr::select(
      dplyr::all_of(vec_group_keys),
      group_budget_source_scale_id = "scale_id",
      group_budget_order = "budget_order",
      group_n_iter_initial = "n_iter_initial",
      group_n_iter_max = "n_iter_max",
      group_n_sampling = "n_sampling",
      group_measured_seconds_per_fit = "measured_seconds_per_fit",
      group_measured_seconds_per_epoch = "measured_seconds_per_epoch"
    )

  data_own_budgets <-
    data_accepted |>
    dplyr::filter(
      stringr::str_detect(
        .data[["selection_reason"]],
        "historical_outlier|paleo_temporal_profile"
      )
    ) |>
    dplyr::mutate(
      own_budget_source_scale_id = .data[["scale_id"]]
    ) |>
    dplyr::select(
      dplyr::all_of(vec_unit_keys),
      "own_budget_source_scale_id",
      own_budget_order = "budget_order",
      own_n_iter_initial = "n_iter_initial",
      own_n_iter_max = "n_iter_max",
      own_n_sampling = "n_sampling",
      own_measured_seconds_per_fit = "measured_seconds_per_fit",
      own_measured_seconds_per_epoch = "measured_seconds_per_epoch"
    )

  res <-
    data_units |>
    dplyr::select(dplyr::all_of(vec_unit_keys)) |>
    dplyr::left_join(data_group_budgets, by = vec_group_keys) |>
    dplyr::left_join(data_own_budgets, by = vec_unit_keys) |>
    dplyr::mutate(
      cv_budget_order = dplyr::coalesce(
        .data[["own_budget_order"]],
        .data[["group_budget_order"]]
      ),
      cv_n_iter_initial = dplyr::coalesce(
        .data[["own_n_iter_initial"]],
        .data[["group_n_iter_initial"]]
      ),
      cv_n_iter_max = dplyr::coalesce(
        .data[["own_n_iter_max"]],
        .data[["group_n_iter_max"]]
      ),
      cv_n_sampling = dplyr::coalesce(
        .data[["own_n_sampling"]],
        .data[["group_n_sampling"]]
      ),
      cv_budget_source_scale_id = dplyr::coalesce(
        .data[["own_budget_source_scale_id"]],
        .data[["group_budget_source_scale_id"]]
      ),
      cv_measured_seconds_per_fit = dplyr::coalesce(
        .data[["own_measured_seconds_per_fit"]],
        .data[["group_measured_seconds_per_fit"]]
      ),
      cv_measured_seconds_per_epoch = dplyr::coalesce(
        .data[["own_measured_seconds_per_epoch"]],
        .data[["group_measured_seconds_per_epoch"]]
      ),
      cv_n_step_size = base::as.numeric(cv_n_step_size),
      cv_n_early_stopping = base::as.integer(cv_n_early_stopping),
      cv_budget_status = dplyr::if_else(
        base::is.na(.data[["cv_budget_order"]]),
        "missing_calibration",
        "calibrated"
      )
    ) |>
    dplyr::select(
      dplyr::all_of(vec_unit_keys),
      "cv_budget_status",
      "cv_budget_source_scale_id",
      "cv_budget_order",
      "cv_n_iter_initial",
      "cv_n_iter_max",
      "cv_n_sampling",
      "cv_n_step_size",
      "cv_n_early_stopping",
      "cv_measured_seconds_per_fit",
      "cv_measured_seconds_per_epoch"
    )

  return(res)
}

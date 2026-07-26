#' @title Validate sjSDM Tuning Repeat Coverage
#' @description
#' Verifies that deterministic work items contain every repeat required by
#' a staged tuning schedule before any candidate-fold fits execute.
#' @param data_work_items
#' Complete work-item table returned by [build_sjsdm_tuning_work_items()].
#' @param data_schedule
#' Tuning schedule returned by [build_sjsdm_tuning_schedule()].
#' @return
#' Invisible `TRUE`. The function aborts when staged repeats are unavailable
#' or candidate fold coverage is inconsistent.
#' @export
validate_sjsdm_tuning_repeat_coverage <- function(
    data_work_items = NULL,
    data_schedule = NULL) {
  vec_work_item_columns <-
    base::c("repeat_id", "fold_id", "candidate_id")

  vec_schedule_columns <-
    base::c("tuning_strategy", "repeat_id")

  assertthat::assert_that(
    base::is.data.frame(data_work_items),
    base::nrow(data_work_items) > 0L,
    base::all(
      vec_work_item_columns %in% base::colnames(data_work_items)
    ),
    msg = "data_work_items is incomplete."
  )

  assertthat::assert_that(
    base::is.data.frame(data_schedule),
    base::nrow(data_schedule) > 0L,
    base::all(
      vec_schedule_columns %in% base::colnames(data_schedule)
    ),
    msg = "data_schedule is incomplete."
  )

  if (
    !base::all(data_schedule[["tuning_strategy"]] == "staged")
  ) {
    return(base::invisible(TRUE))
  }

  vec_required_repeats <-
    base::unique(data_schedule[["repeat_id"]])

  vec_available_repeats <-
    base::unique(data_work_items[["repeat_id"]])

  vec_missing_repeats <-
    base::setdiff(
      vec_required_repeats,
      vec_available_repeats
    )

  if (
    base::length(vec_missing_repeats) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Staged tuning requires assignment repeats that are unavailable.",
        "i" = "Missing repeat IDs: {vec_missing_repeats}.",
        "i" = paste(
          "The resolved CV strategy may have fallen back to",
          "single-repeat leave-one-location-out."
        )
      )
    )
  }

  data_fold_counts <-
    data_work_items |>
    dplyr::filter(
      .data[["repeat_id"]] %in% .env[["vec_required_repeats"]]
    ) |>
    dplyr::distinct(
      .data[["repeat_id"]],
      .data[["candidate_id"]],
      .data[["fold_id"]]
    ) |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["candidate_id"]],
      name = "n_folds"
    )

  data_repeat_fold_ranges <-
    data_fold_counts |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::summarise(
      n_candidates = dplyr::n(),
      min_folds = base::min(.data[["n_folds"]]),
      max_folds = base::max(.data[["n_folds"]]),
      .groups = "drop"
    )

  n_candidates <-
    dplyr::n_distinct(data_work_items[["candidate_id"]])

  flag_complete_coverage <-
    base::all(
      data_repeat_fold_ranges[["n_candidates"]] == n_candidates
    ) &&
    base::all(
      data_repeat_fold_ranges[["min_folds"]] ==
        data_repeat_fold_ranges[["max_folds"]]
    )

  if (
    !flag_complete_coverage
  ) {
    cli::cli_abort(
      "Staged tuning assignment repeats have inconsistent candidate folds."
    )
  }

  base::return(base::invisible(TRUE))
}

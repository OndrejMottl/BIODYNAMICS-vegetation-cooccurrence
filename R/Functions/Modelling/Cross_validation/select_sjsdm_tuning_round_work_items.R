#' @title Select sjSDM Tuning-Round Work Items
#' @description
#' Selects the deterministic work items allowed to execute in one staged
#' tuning round. Later rounds require the previous tier-wide survivor
#' decision and fail closed when that evidence is absent or inconsistent.
#' @param data_work_items
#' Work-item table returned by [build_sjsdm_tuning_work_items()].
#' @param data_schedule
#' Staged schedule returned by [build_sjsdm_tuning_schedule()].
#' @param round_id
#' Positive integer tuning-round identifier to select.
#' @param data_prior_decisions
#' Tier-wide decision table returned by
#' [select_sjsdm_staged_survivors()] for the preceding round. Must be `NULL`
#' for round one.
#' @return
#' Work-item tibble for the configured repeat and tier-wide candidate set,
#' with `round_id` added as the first column. Existing `work_item_id` values
#' are preserved so completed fits remain reusable.
#' @export
select_sjsdm_tuning_round_work_items <- function(
    data_work_items = NULL,
    data_schedule = NULL,
    round_id = NULL,
    data_prior_decisions = NULL) {
  vec_work_item_columns <-
    base::c(
      "work_item_id",
      "repeat_id",
      "fold_id",
      "candidate_id"
    )

  vec_schedule_columns <-
    base::c(
      "tuning_strategy",
      "round_id",
      "repeat_id",
      "n_candidates_entering",
      "n_candidates_surviving"
    )

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

  flag_valid_round_id <-
    base::is.numeric(round_id) &&
    base::length(round_id) == 1L &&
    base::is.finite(round_id) &&
    round_id >= 1L &&
    round_id == base::as.integer(round_id)

  assertthat::assert_that(
    flag_valid_round_id,
    msg = "round_id must be one positive integer."
  )

  if (
    !base::all(data_schedule[["tuning_strategy"]] == "staged")
  ) {
    cli::cli_abort("Round work-item selection requires staged tuning.")
  }

  data_round <-
    data_schedule |>
    dplyr::filter(.data[["round_id"]] == .env[["round_id"]])

  if (
    base::nrow(data_round) != 1L
  ) {
    cli::cli_abort("round_id must identify exactly one schedule row.")
  }

  repeat_id <-
    data_round[["repeat_id"]][[1L]]

  n_candidates_entering <-
    data_round[["n_candidates_entering"]][[1L]]

  vec_available_candidates <-
    data_work_items[["candidate_id"]] |>
    base::unique() |>
    base::sort()

  if (
    round_id == 1L
  ) {
    if (
      !base::is.null(data_prior_decisions)
    ) {
      cli::cli_abort("Round one must not use a prior survivor decision.")
    }

    vec_selected_candidates <-
      vec_available_candidates
  } else {
    if (
      base::is.null(data_prior_decisions)
    ) {
      cli::cli_abort(
        "A previous tier-wide survivor decision is required."
      )
    }

    vec_decision_columns <-
      base::c(
        "round_id",
        "candidate_id",
        "staged_decision"
      )

    assertthat::assert_that(
      base::is.data.frame(data_prior_decisions),
      base::all(
        vec_decision_columns %in%
          base::colnames(data_prior_decisions)
      ),
      msg = "data_prior_decisions is incomplete."
    )

    if (
      !base::all(
        data_prior_decisions[["candidate_id"]] %in%
          vec_available_candidates
      )
    ) {
      cli::cli_abort(
        "The tier decision candidate set does not match the work items."
      )
    }

    data_previous_round <-
      data_schedule |>
      dplyr::filter(.data[["round_id"]] == .env[["round_id"]] - 1L)

    n_candidates_previously_entering <-
      data_previous_round[["n_candidates_entering"]][[1L]]

    flag_complete_decisions <-
      base::nrow(data_prior_decisions) ==
        n_candidates_previously_entering &&
      !base::any(
        base::duplicated(data_prior_decisions[["candidate_id"]])
      ) &&
      base::all(
        data_prior_decisions[["round_id"]] == round_id - 1L
      ) &&
      base::all(
        data_prior_decisions[["staged_decision"]] %in%
          base::c("survive", "prune")
      )

    if (
      !flag_complete_decisions
    ) {
      cli::cli_abort(
        "Tier decisions must cover every entering candidate exactly once."
      )
    }

    vec_selected_candidates <-
      data_prior_decisions |>
      dplyr::filter(.data[["staged_decision"]] == "survive") |>
      dplyr::pull(.data[["candidate_id"]]) |>
      base::sort()
  }

  if (
    base::length(vec_selected_candidates) != n_candidates_entering
  ) {
    cli::cli_abort(
      "The tier survivor count does not match the tuning schedule."
    )
  }

  res <-
    data_work_items |>
    dplyr::filter(
      .data[["repeat_id"]] == .env[["repeat_id"]],
      .data[["candidate_id"]] %in% .env[["vec_selected_candidates"]]
    ) |>
    dplyr::mutate(
      round_id = base::as.integer(round_id),
      .before = 1L
    ) |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]]
    )

  data_candidate_fold_counts <-
    res |>
    dplyr::count(.data[["candidate_id"]], name = "n_folds")

  flag_complete_work_items <-
    base::nrow(data_candidate_fold_counts) == n_candidates_entering &&
    dplyr::n_distinct(data_candidate_fold_counts[["n_folds"]]) == 1L &&
    !base::any(base::duplicated(res[["work_item_id"]]))

  if (
    !flag_complete_work_items
  ) {
    cli::cli_abort(
      "Every entering candidate must have the same unique fold work items."
    )
  }

  return(res)
}

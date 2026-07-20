#' @title Build Cumulative sjSDM Tuning Work Items
#' @description
#' Expands staged tuning through the first unfinished round while preserving
#' deterministic work-item identities from all completed rounds. A later
#' round is included only when the preceding tier-wide survivor decision is
#' available.
#' @param data_work_items
#' Complete work-item table returned by [build_sjsdm_tuning_work_items()].
#' @param data_schedule
#' Staged schedule returned by [build_sjsdm_tuning_schedule()].
#' @param list_prior_decisions
#' Ordered list of consecutive tier-wide decision tables, beginning with
#' round one. An empty list authorizes round one only.
#' @return
#' Cumulative work-item tibble through the first authorized unfinished round.
#' Existing `work_item_id` values are preserved for dynamic-branch reuse.
#' @export
build_sjsdm_cumulative_tuning_work_items <- function(
    data_work_items = NULL,
    data_schedule = NULL,
    list_prior_decisions = base::list()) {
  assertthat::assert_that(
    base::is.data.frame(data_work_items),
    base::nrow(data_work_items) > 0L,
    base::is.data.frame(data_schedule),
    base::nrow(data_schedule) > 0L,
    base::is.list(list_prior_decisions),
    msg = "Cumulative tuning inputs are incomplete."
  )

  n_rounds <-
    base::nrow(data_schedule)

  n_prior_decisions <-
    base::length(list_prior_decisions)

  if (
    n_prior_decisions > n_rounds - 1L
  ) {
    cli::cli_abort(
      "Tier decisions are accepted only for non-final rounds."
    )
  }

  if (
    n_prior_decisions > 0L
  ) {
    flag_data_frames <-
      list_prior_decisions |>
      purrr::map_lgl(base::is.data.frame) |>
      base::all()

    assertthat::assert_that(
      flag_data_frames,
      msg = "Every prior decision must be a data frame."
    )

    vec_decision_round_ids <-
      list_prior_decisions |>
      purrr::map_int(
        .f = ~ {
          if (
            !"round_id" %in% base::colnames(.x) ||
              dplyr::n_distinct(.x[["round_id"]]) != 1L
          ) {
            return(NA_integer_)
          }

          return(base::as.integer(.x[["round_id"]][[1L]]))
        }
      )

    if (
      !base::identical(
        vec_decision_round_ids,
        base::seq_len(n_prior_decisions)
      )
    ) {
      cli::cli_abort(
        "Tier decisions must contain consecutive rounds beginning at one."
      )
    }
  }

  vec_authorized_rounds <-
    base::seq_len(n_prior_decisions + 1L)

  list_round_work_items <-
    vec_authorized_rounds |>
    purrr::map(
      .f = ~ select_sjsdm_tuning_round_work_items(
        data_work_items = data_work_items,
        data_schedule = data_schedule,
        round_id = .x,
        data_prior_decisions = if (
          .x == 1L
        ) {
          NULL
        } else {
          list_prior_decisions[[.x - 1L]]
        }
      )
    )

  res <-
    list_round_work_items |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["round_id"]],
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]]
    )

  if (
    base::any(base::duplicated(res[["work_item_id"]]))
  ) {
    cli::cli_abort(
      "Cumulative tuning work-item identities must remain unique."
    )
  }

  return(res)
}

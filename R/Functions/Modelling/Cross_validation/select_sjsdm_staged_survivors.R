#' @title Select sjSDM Staged-Tuning Survivors
#' @description
#' Deterministically ranks tier-pooled candidate evidence and returns the
#' candidates allowed to enter the next tuning round. Candidates without
#' complete converged evidence remain in the decision table but are pruned.
#' @param data_candidate_aggregation
#' Candidate aggregation table containing `candidate_id`,
#' `normalized_loss_equal_id`, and `aggregation_status`.
#' @param survivor_count
#' Positive integer number of candidates to retain.
#' @param round_id
#' Positive integer tuning-round identifier.
#' @return
#' Tibble containing `round_id`, `candidate_id`, `candidate_rank`,
#' `normalized_loss_equal_id`, and `staged_decision` for every candidate.
#' Eligible candidates are ordered first by loss and then candidate identifier.
#' Ineligible candidates follow and always receive a `prune` decision.
#' @examples
#' select_sjsdm_staged_survivors(
#'   data_candidate_aggregation = tibble::tibble(
#'     candidate_id = c("candidate_001", "candidate_002"),
#'     normalized_loss_equal_id = c(0.2, 0.3),
#'     aggregation_status = c("ok", "ok")
#'   ),
#'   survivor_count = 1L,
#'   round_id = 1L
#' )
#' @export
select_sjsdm_staged_survivors <- function(
    data_candidate_aggregation = NULL,
    survivor_count = NULL,
    round_id = NULL) {
  vec_required_columns <-
    base::c(
      "candidate_id",
      "normalized_loss_equal_id",
      "aggregation_status"
    )

  assertthat::assert_that(
    base::is.data.frame(data_candidate_aggregation),
    base::nrow(data_candidate_aggregation) > 1L,
    base::all(
      vec_required_columns %in%
        base::colnames(data_candidate_aggregation)
    ),
    msg = "data_candidate_aggregation is incomplete."
  )

  vec_candidate_ids <-
    data_candidate_aggregation[["candidate_id"]]

  assertthat::assert_that(
    base::is.character(vec_candidate_ids),
    base::all(!base::is.na(vec_candidate_ids)),
    base::all(base::nzchar(vec_candidate_ids)),
    !base::any(base::duplicated(vec_candidate_ids)),
    msg = "candidate_id must contain unique non-missing strings."
  )

  flag_valid_survivor_count <-
    base::is.numeric(survivor_count) &&
    base::length(survivor_count) == 1L &&
    base::is.finite(survivor_count) &&
    survivor_count >= 1L &&
    survivor_count == base::as.integer(survivor_count)

  assertthat::assert_that(
    flag_valid_survivor_count,
    msg = "survivor_count must be one positive integer."
  )

  if (
    survivor_count >= base::nrow(data_candidate_aggregation)
  ) {
    cli::cli_abort(
      "survivor_count must retain fewer candidates than entered."
    )
  }

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

  vec_candidate_eligible <-
    data_candidate_aggregation[["aggregation_status"]] %in% "ok" &
    base::is.finite(
      data_candidate_aggregation[["normalized_loss_equal_id"]]
    )

  n_candidates_eligible <-
    base::sum(vec_candidate_eligible)

  if (
    n_candidates_eligible < survivor_count
  ) {
    message_candidate_count <-
      if (n_candidates_eligible == 1L) {
        "Only 1 candidate has complete tier evidence"
      } else {
        stringr::str_glue(
          "Only {n_candidates_eligible} candidates have complete tier ",
          "evidence"
        )
      }

    cli::cli_abort(
      stringr::str_glue(
        "{message_candidate_count}; {survivor_count} survivors are ",
        "required."
      )
    )
  }

  res <-
    data_candidate_aggregation |>
    dplyr::mutate(
      candidate_eligible = .env[["vec_candidate_eligible"]]
    ) |>
    dplyr::arrange(
      dplyr::desc(.data[["candidate_eligible"]]),
      .data[["normalized_loss_equal_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::mutate(
      round_id = base::as.integer(round_id),
      candidate_rank = base::seq_len(dplyr::n()),
      staged_decision = dplyr::if_else(
        .data[["candidate_eligible"]] &
          .data[["candidate_rank"]] <= survivor_count,
        "survive",
        "prune"
      ),
      .before = 1L
    ) |>
    dplyr::select(
      "round_id",
      "candidate_id",
      "candidate_rank",
      "normalized_loss_equal_id",
      "staged_decision"
    )

  return(res)
}

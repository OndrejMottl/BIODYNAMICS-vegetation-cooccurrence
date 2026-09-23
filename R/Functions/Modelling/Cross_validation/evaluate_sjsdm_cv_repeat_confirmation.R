#' @title Evaluate sjSDM CV Repeat Confirmation
#' @description
#' Determines whether a provisional repeat-one candidate is confirmed by
#' repeat two either as the exact winner or as a practically equivalent
#' candidate within a registered relative loss tolerance.
#' @param data_candidate_summary
#' Candidate-level summary containing `repeat_id`, `candidate_id`,
#' `candidate_loss`, and `candidate_complete`.
#' @param provisional_candidate_id
#' Character scalar identifying the repeat-one provisional winner.
#' @param relative_loss_tolerance
#' Non-negative relative loss gap allowed above the repeat-two minimum.
#' @return
#' One-row tibble containing the repeat-two winner, exact-winner flag,
#' relative loss gap, tolerance, practical-equivalence flag, and confirmation.
#' @export
evaluate_sjsdm_cv_repeat_confirmation <- function(
    data_candidate_summary = NULL,
    provisional_candidate_id = NULL,
    relative_loss_tolerance = 0.02) {
  vec_required_columns <-
    base::c(
      "repeat_id",
      "candidate_id",
      "candidate_loss",
      "candidate_complete"
    )

  assertthat::assert_that(
    base::is.data.frame(data_candidate_summary),
    base::all(
      vec_required_columns %in% base::colnames(data_candidate_summary)
    ),
    base::is.character(provisional_candidate_id),
    base::length(provisional_candidate_id) == 1L,
    !base::is.na(provisional_candidate_id),
    base::nzchar(provisional_candidate_id),
    base::is.numeric(relative_loss_tolerance),
    base::length(relative_loss_tolerance) == 1L,
    base::is.finite(relative_loss_tolerance),
    relative_loss_tolerance >= 0,
    msg = "Repeat-confirmation inputs are incomplete."
  )

  data_repeat_two <-
    data_candidate_summary |>
    dplyr::filter(
      .data[["repeat_id"]] == 2L,
      .data[["candidate_complete"]],
      base::is.finite(.data[["candidate_loss"]])
    )

  assertthat::assert_that(
    !base::any(base::duplicated(data_repeat_two[["candidate_id"]])),
    msg = "Repeat-two candidate summaries must be unique."
  )

  data_repeat_two_winner <-
    data_repeat_two |>
    dplyr::arrange(
      .data[["candidate_loss"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::slice_head(n = 1L)
  data_provisional_repeat_two <-
    data_repeat_two |>
    dplyr::filter(
      .data[["candidate_id"]] == provisional_candidate_id
    )

  flag_complete <-
    base::nrow(data_repeat_two_winner) == 1L &&
    base::nrow(data_provisional_repeat_two) == 1L

  if (
    !flag_complete
  ) {
    res_incomplete <-
      tibble::tibble(
        repeat_two_candidate_id = NA_character_,
        repeat_two_exact_winner = FALSE,
        repeat_two_relative_loss_gap = NA_real_,
        repeat_two_loss_tolerance = relative_loss_tolerance,
        repeat_two_practically_equivalent = FALSE,
        repeat_two_confirmed = FALSE
      )

    return(res_incomplete)
  }

  repeat_two_candidate_id <-
    data_repeat_two_winner[["candidate_id"]][[1L]]
  repeat_two_best_loss <-
    data_repeat_two_winner[["candidate_loss"]][[1L]]
  provisional_repeat_two_loss <-
    data_provisional_repeat_two[["candidate_loss"]][[1L]]
  repeat_two_relative_loss_gap <-
    base::max(
      0,
      (provisional_repeat_two_loss - repeat_two_best_loss) /
        base::max(
          base::abs(repeat_two_best_loss),
          .Machine[["double.eps"]]
        )
    )
  repeat_two_exact_winner <-
    base::identical(
      provisional_candidate_id,
      repeat_two_candidate_id
    )
  repeat_two_practically_equivalent <-
    repeat_two_relative_loss_gap <= relative_loss_tolerance

  res <-
    tibble::tibble(
      repeat_two_candidate_id = repeat_two_candidate_id,
      repeat_two_exact_winner = repeat_two_exact_winner,
      repeat_two_relative_loss_gap = repeat_two_relative_loss_gap,
      repeat_two_loss_tolerance = relative_loss_tolerance,
      repeat_two_practically_equivalent =
        repeat_two_practically_equivalent,
      repeat_two_confirmed = repeat_two_practically_equivalent
    )

  return(res)
}

#' @title Build an sjSDM Tuning Round Plan
#' @description
#' Constructs the deterministic exhaustive or cumulative staged orchestration
#' plan. Staged execution preserves the optimized three-round 8 to 4 to 2
#' policy encoded by the tuning schedule.
#' @param tuning_strategy
#' `exhaustive` or `staged`.
#' @param n_rounds
#' Configured positive round count. Staged execution requires three rounds.
#' @return
#' Tibble with round identifiers, final-round flags, and tier target names.
#' @export
build_sjsdm_tuning_round_plan <- function(
    tuning_strategy = NULL,
    n_rounds = NULL) {
  assertthat::assert_that(
    base::is.character(tuning_strategy),
    base::length(tuning_strategy) == 1L,
    tuning_strategy %in% base::c("exhaustive", "staged"),
    base::is.numeric(n_rounds),
    base::length(n_rounds) == 1L,
    base::is.finite(n_rounds),
    n_rounds >= 1L,
    n_rounds == base::as.integer(n_rounds),
    msg = "Tuning round-plan inputs are invalid."
  )

  n_rounds <-
    base::as.integer(n_rounds)

  if (
    tuning_strategy == "staged" && n_rounds != 3L
  ) {
    cli::cli_abort(
      "Staged orchestration currently requires exactly three rounds."
    )
  }

  vec_round_ids <-
    if (
      tuning_strategy == "staged"
    ) {
      base::seq_len(n_rounds)
    } else {
      1L
    }

  vec_final_round <-
    vec_round_ids == base::max(vec_round_ids)

  vec_tier_target_names <-
    if (
      tuning_strategy == "exhaustive"
    ) {
      base::rep(NA_character_, base::length(vec_round_ids))
    } else {
      dplyr::if_else(
        vec_final_round,
        "data_sjsdm_tier_regularization_artifacts",
        stringr::str_c(
          "data_sjsdm_tier_survivor_decisions_round_",
          vec_round_ids
        )
      )
    }

  res <-
    tibble::tibble(
      round_id = vec_round_ids,
      final_round = vec_final_round,
      tier_target_name = vec_tier_target_names
    )

  return(res)
}

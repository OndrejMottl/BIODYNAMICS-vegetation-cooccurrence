#' @title Build an sjSDM Tuning Schedule
#' @description
#' Validates exhaustive or staged cross-validation tuning settings and builds
#' the deterministic repeat-level candidate budget used by every model
#' pipeline.
#' @param tuning_strategy
#' Character scalar. Either `"exhaustive"` or `"staged"`.
#' @param n_candidates
#' Positive integer number of regularization candidates.
#' @param repeat_ids
#' Unique positive integer repeat identifiers in execution order.
#' @param survivor_counts
#' Integer counts retained after each non-final staged round. Ignored for
#' exhaustive tuning.
#' @return
#' Tibble with one row per tuning round and columns `tuning_strategy`,
#' `strategy_version`, `round_id`, `repeat_id`, `n_candidates_entering`, and
#' `n_candidates_surviving`.
#' @examples
#' build_sjsdm_tuning_schedule(
#'   tuning_strategy = "staged",
#'   n_candidates = 8L,
#'   repeat_ids = 1:3,
#'   survivor_counts = c(4L, 2L)
#' )
#' @export
build_sjsdm_tuning_schedule <- function(
    tuning_strategy = NULL,
    n_candidates = NULL,
    repeat_ids = NULL,
    survivor_counts = NULL) {
  assertthat::assert_that(
    base::is.character(tuning_strategy),
    base::length(tuning_strategy) == 1L,
    !base::is.na(tuning_strategy),
    tuning_strategy %in% base::c("exhaustive", "staged"),
    msg = "tuning_strategy must be exhaustive or staged."
  )

  flag_valid_candidate_count <-
    base::is.numeric(n_candidates) &&
    base::length(n_candidates) == 1L &&
    base::is.finite(n_candidates) &&
    n_candidates >= 1L &&
    n_candidates == base::as.integer(n_candidates)

  assertthat::assert_that(
    flag_valid_candidate_count,
    msg = "n_candidates must be one positive integer."
  )

  flag_valid_repeat_ids <-
    base::is.numeric(repeat_ids) &&
    base::length(repeat_ids) > 0L &&
    base::all(base::is.finite(repeat_ids)) &&
    base::all(repeat_ids >= 1L) &&
    base::all(repeat_ids == base::as.integer(repeat_ids)) &&
    !base::any(base::duplicated(repeat_ids))

  assertthat::assert_that(
    flag_valid_repeat_ids,
    msg = "repeat_ids must contain unique positive integers."
  )

  repeat_ids <-
    base::as.integer(repeat_ids)

  if (
    !base::identical(
      base::sort(repeat_ids),
      base::seq_along(repeat_ids)
    )
  ) {
    cli::cli_abort(
      "repeat_ids must be a permutation of the configured repeats."
    )
  }

  n_candidates <-
    base::as.integer(n_candidates)

  if (
    tuning_strategy == "exhaustive"
  ) {
    vec_surviving <-
      base::rep(n_candidates, base::length(repeat_ids))

    vec_surviving[[base::length(vec_surviving)]] <- 1L

    res_exhaustive <-
      tibble::tibble(
        tuning_strategy = "exhaustive",
        strategy_version = "sjsdm_exhaustive_tuning_v1",
        round_id = base::seq_along(repeat_ids),
        repeat_id = repeat_ids,
        n_candidates_entering = base::rep(
          n_candidates,
          base::length(repeat_ids)
        ),
        n_candidates_surviving = vec_surviving
      )

    return(res_exhaustive)
  }

  if (
    n_candidates < 2L
  ) {
    cli::cli_abort("Staged tuning requires at least two candidates.")
  }

  flag_valid_survivor_counts <-
    base::is.numeric(survivor_counts) &&
    base::all(base::is.finite(survivor_counts)) &&
    base::all(survivor_counts >= 1L) &&
    base::all(
      survivor_counts == base::as.integer(survivor_counts)
    )

  assertthat::assert_that(
    flag_valid_survivor_counts,
    msg = "survivor_counts must contain positive integers."
  )

  if (
    base::length(survivor_counts) !=
      base::length(repeat_ids) - 1L
  ) {
    cli::cli_abort(
      "Staged survivor counts must be one fewer than repeat IDs."
    )
  }

  survivor_counts <-
    base::as.integer(survivor_counts)

  vec_candidate_budget <-
    base::c(n_candidates, survivor_counts)

  if (
    base::any(base::diff(vec_candidate_budget) >= 0L)
  ) {
    cli::cli_abort(
      "Staged candidate counts must strictly decrease by round."
    )
  }

  res <-
    tibble::tibble(
      tuning_strategy = "staged",
      strategy_version = "sjsdm_staged_tuning_v1",
      round_id = base::seq_along(repeat_ids),
      repeat_id = repeat_ids,
      n_candidates_entering = vec_candidate_budget,
      n_candidates_surviving = base::c(survivor_counts, 1L)
    )

  return(res)
}

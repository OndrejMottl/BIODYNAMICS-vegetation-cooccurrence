#' @title Build sjSDM Tier Survivor Artifacts
#' @description
#' Pools one tuning round across every source ID in each compatible model
#' context, then records the tier-wide candidates that may enter the next
#' round. Pruning never occurs from a single unit's evidence.
#' @param data_tuning_summary
#' Bound unit tuning summaries for exactly one staged round.
#' @param data_schedule
#' Staged schedule returned by [build_sjsdm_tuning_schedule()].
#' @param round_id
#' Positive integer tuning-round identifier represented by the summaries.
#' @param data_prior_decisions
#' Tier-wide decisions from the preceding round. Required after round one and
#' used to restrict cumulative evidence to the candidates entering this round.
#' @return
#' Named list containing `data_survivor_decisions`,
#' `data_source_candidate_loss`, `data_candidate_aggregation`, and the
#' cumulative `data_tuning_entering` tibble. Decision rows retain model
#' context, strategy, round, and repeat provenance.
#' @export
build_sjsdm_tier_survivor_artifacts <- function(
    data_tuning_summary = NULL,
    data_schedule = NULL,
    round_id = NULL,
    data_prior_decisions = NULL) {
  vec_context_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

  vec_schedule_columns <-
    base::c(
      "tuning_strategy",
      "strategy_version",
      "round_id",
      "repeat_id",
      "n_candidates_entering",
      "n_candidates_surviving"
    )

  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::nrow(data_tuning_summary) > 0L,
    base::all(
      base::c(vec_context_columns, "repeat_id") %in%
        base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary is missing round or context columns."
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
    cli::cli_abort("Tier survivor artifacts require staged tuning.")
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

  vec_expected_repeats <-
    data_schedule |>
    dplyr::filter(.data[["round_id"]] <= .env[["round_id"]]) |>
    dplyr::pull(.data[["repeat_id"]]) |>
    base::sort()

  data_tuning_available <-
    data_tuning_summary |>
    dplyr::filter(
      .data[["repeat_id"]] %in% .env[["vec_expected_repeats"]]
    )

  if (
    base::nrow(data_tuning_available) == 0L
  ) {
    cli::cli_abort(
      "No tuning summaries contain the configured repeats for the round."
    )
  }

  if (
    round_id == 1L
  ) {
    if (
      !base::is.null(data_prior_decisions)
    ) {
      cli::cli_abort("Round one must not use preceding tier decisions.")
    }

    data_tuning_entering <-
      data_tuning_available
  } else {
    if (
      base::is.null(data_prior_decisions)
    ) {
      cli::cli_abort(
        "Later rounds require the preceding tier decisions."
      )
    }

    vec_decision_columns <-
      base::c(
        vec_context_columns,
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

    data_previous_round <-
      data_schedule |>
      dplyr::filter(.data[["round_id"]] == .env[["round_id"]] - 1L)

    n_previous_entering <-
      data_previous_round[["n_candidates_entering"]][[1L]]

    n_current_entering <-
      data_round[["n_candidates_entering"]][[1L]]

    data_decision_counts <-
      data_prior_decisions |>
      dplyr::group_by(
        dplyr::across(dplyr::all_of(vec_context_columns))
      ) |>
      dplyr::summarise(
        n_decisions = dplyr::n_distinct(.data[["candidate_id"]]),
        n_survivors = base::sum(
          .data[["staged_decision"]] == "survive"
        ),
        n_round_ids = dplyr::n_distinct(.data[["round_id"]]),
        prior_round_id = dplyr::first(.data[["round_id"]]),
        .groups = "drop"
      )

    flag_complete_prior_decisions <-
      base::all(
        data_decision_counts[["n_decisions"]] ==
          n_previous_entering
      ) &&
      base::all(
        data_decision_counts[["n_survivors"]] ==
          n_current_entering
      ) &&
      base::all(data_decision_counts[["n_round_ids"]] == 1L) &&
      base::all(
        data_decision_counts[["prior_round_id"]] == round_id - 1L
      )

    if (
      !flag_complete_prior_decisions
    ) {
      cli::cli_abort(
        "Preceding tier decisions are incomplete or inconsistent."
      )
    }

    data_summary_contexts <-
      data_tuning_available |>
      dplyr::distinct(
        dplyr::across(dplyr::all_of(vec_context_columns))
      )

    data_decision_contexts <-
      data_prior_decisions |>
      dplyr::distinct(
        dplyr::across(dplyr::all_of(vec_context_columns))
      )

    flag_contexts_match <-
      base::nrow(
        dplyr::anti_join(
          data_summary_contexts,
          data_decision_contexts,
          by = vec_context_columns
        )
      ) == 0L &&
      base::nrow(
        dplyr::anti_join(
          data_decision_contexts,
          data_summary_contexts,
          by = vec_context_columns
        )
      ) == 0L

    if (
      !flag_contexts_match
    ) {
      cli::cli_abort(
        "Summary and tier-decision model contexts must match."
      )
    }

    data_survivors <-
      data_prior_decisions |>
      dplyr::filter(.data[["staged_decision"]] == "survive") |>
      dplyr::select(
        dplyr::all_of(vec_context_columns),
        "candidate_id"
      )

    data_tuning_entering <-
      data_tuning_available |>
      dplyr::inner_join(
        data_survivors,
        by = base::c(vec_context_columns, "candidate_id")
      )
  }

  data_repeat_sets <-
    data_tuning_entering |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_context_columns)),
      .data[["source_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      repeat_ids = base::list(
        base::sort(base::unique(.data[["repeat_id"]]))
      ),
      .groups = "drop"
    )

  flag_complete_repeats <-
    data_repeat_sets[["repeat_ids"]] |>
    purrr::map_lgl(
      .f = ~ base::identical(.x, vec_expected_repeats)
    ) |>
    base::all()

  if (
    !flag_complete_repeats
  ) {
    cli::cli_abort(
      "Every candidate must contain all configured repeats through the round."
    )
  }

  list_context_summaries <-
    data_tuning_entering |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_context_columns))
    ) |>
    dplyr::group_split(.keep = TRUE)

  list_aggregations <-
    list_context_summaries |>
    purrr::map(
      .f = ~ aggregate_sjsdm_tuning_by_tier(
        data_tuning_summary = .x
      )
    )

  n_candidates_entering <-
    data_round[["n_candidates_entering"]][[1L]]

  vec_candidate_counts <-
    list_aggregations |>
    purrr::map_int(
      .f = ~ base::nrow(.x[["candidate_aggregation"]])
    )

  flag_candidate_counts_match <-
    base::all(vec_candidate_counts == n_candidates_entering)

  if (
    !flag_candidate_counts_match
  ) {
    cli::cli_abort(
      "Every model context must contain the scheduled candidate count."
    )
  }

  survivor_count <-
    data_round[["n_candidates_surviving"]][[1L]]

  strategy_version <-
    data_round[["strategy_version"]][[1L]]

  list_decisions <-
    list_aggregations |>
    purrr::map(
      .f = ~ {
        data_aggregation <-
          .x[["candidate_aggregation"]]

        data_decisions <-
          select_sjsdm_staged_survivors(
            data_candidate_aggregation = data_aggregation,
            survivor_count = survivor_count,
            round_id = round_id
          )

        data_context <-
          data_aggregation |>
          dplyr::slice_head(n = 1L) |>
          dplyr::select(dplyr::all_of(vec_context_columns))

        res_decisions <-
          tidyr::crossing(
            data_context,
            data_decisions
          ) |>
          dplyr::mutate(
            strategy_version = strategy_version,
            repeat_id = base::as.integer(repeat_id),
            n_candidates_entering = n_candidates_entering,
            n_candidates_surviving = survivor_count,
            .after = "round_id"
          )

        return(res_decisions)
      }
    )

  res <-
    base::list(
      data_survivor_decisions = list_decisions |>
        purrr::list_rbind(),
      data_source_candidate_loss = list_aggregations |>
        purrr::map("source_candidate_loss") |>
        purrr::list_rbind() |>
        dplyr::mutate(
          round_id = base::as.integer(round_id),
          strategy_version = strategy_version,
          repeat_id = base::as.integer(repeat_id),
          .before = 1L
        ),
      data_candidate_aggregation = list_aggregations |>
        purrr::map("candidate_aggregation") |>
        purrr::list_rbind() |>
        dplyr::mutate(
          round_id = base::as.integer(round_id),
          strategy_version = strategy_version,
          repeat_id = base::as.integer(repeat_id),
          .before = 1L
        ),
      data_tuning_entering = data_tuning_entering
    )

  return(res)
}

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
#' @return
#' Named list containing `data_survivor_decisions`,
#' `data_source_candidate_loss`, and `data_candidate_aggregation` tibbles.
#' Decision rows retain model context, strategy, round, and repeat provenance.
#' @export
build_sjsdm_tier_survivor_artifacts <- function(
    data_tuning_summary = NULL,
    data_schedule = NULL,
    round_id = NULL) {
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

  if (
    !base::all(data_tuning_summary[["repeat_id"]] == repeat_id)
  ) {
    cli::cli_abort(
      "Every summary must represent the configured repeat for the round."
    )
  }

  list_context_summaries <-
    data_tuning_summary |>
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
        )
    )

  return(res)
}

#' @title Build Programmatic Trait Review Triage
#' @description
#' Resolves candidates without positive correction evidence to proposed
#' no-action decisions and groups reproducible correction hypotheses for
#' cost-gated agent investigation.
#' @param data_candidate_recommendations
#' Candidate recommendations from [diagnose_trait_review_candidates()].
#' @param data_approved_decisions
#' Current canonical decisions from [load_trait_review_decisions()].
#' @param data_proposal_diagnostics
#' Recovered selector diagnostics from
#' [diagnose_trait_review_candidates()].
#' @param data_dataset_evidence
#' Dataset summaries from [build_trait_review_evidence_packets()].
#' @param data_record_evidence
#' Record evidence from [build_trait_review_evidence_packets()].
#' @param data_agent_adjudications
#' Completed adjudications. May be a zero-row data frame.
#' @param evidence_reference
#' Non-empty path to the human-readable triage report.
#' @param min_source_pattern_candidates
#' Minimum candidates sharing a source/factor pattern before escalation.
#' @param source_factor_relative_tolerance
#' Maximum relative error from factors 10, 100, or 1000.
#' @param agent_groups_per_batch
#' Maximum exception groups assigned to one initial agent batch.
#' @return
#' A named list containing candidate triage, proposed no-action decisions,
#' exception memberships and groups, a cost-gated agent queue, and summary.
#' @export
build_trait_review_programmatic_triage <- function(
    data_candidate_recommendations,
    data_approved_decisions,
    data_proposal_diagnostics,
    data_dataset_evidence,
    data_record_evidence,
    data_agent_adjudications,
    evidence_reference,
    min_source_pattern_candidates = 3L,
    source_factor_relative_tolerance = 0.25,
    agent_groups_per_batch = 10L) {
  list_inputs <-
    base::list(
      candidates = data_candidate_recommendations,
      decisions = data_approved_decisions,
      proposals = data_proposal_diagnostics,
      datasets = data_dataset_evidence,
      records = data_record_evidence,
      adjudications = data_agent_adjudications
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All programmatic-triage inputs must be data frames."
  )
  list_required_columns <-
    base::list(
      candidates = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "deterministic_outcome",
        "n_records_current",
        "candidate_impact_score"
      ),
      decisions = base::c("candidate_id", "review_status"),
      proposals = base::c(
        "decision_id",
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "trait_name",
        "dataset_id",
        "value_lower",
        "value_lower_inclusive",
        "value_upper",
        "value_upper_inclusive",
        "action",
        "scale_factor",
        "proposal_match_status"
      ),
      datasets = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "dataset_id",
        "dataset_name",
        "trait_name",
        "n_records_source",
        "source_median"
      ),
      records = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "dataset_id",
        "dataset_name",
        "trait_name",
        "trait_value"
      ),
      adjudications = base::c(
        "candidate_id",
        "review_role",
        "recommendation",
        "evidence_reference"
      )
    )
  vec_has_required_columns <-
    purrr::imap_lgl(
      list_required_columns,
      ~ base::all(.x %in% base::names(list_inputs[[.y]]))
    )
  assertthat::assert_that(
    base::all(vec_has_required_columns),
    msg = "Programmatic-triage inputs are missing required columns."
  )
  assertthat::assert_that(
    base::is.character(evidence_reference),
    base::length(evidence_reference) == 1L,
    !base::is.na(evidence_reference),
    base::nzchar(evidence_reference),
    msg = "'evidence_reference' must be one non-empty string."
  )
  list_integer_arguments <-
    base::list(
      min_source_pattern_candidates =
        min_source_pattern_candidates,
      agent_groups_per_batch = agent_groups_per_batch
    )
  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        list_integer_arguments,
        ~ base::is.numeric(.x) &&
          base::length(.x) == 1L &&
          base::is.finite(.x) &&
          .x >= 1L &&
          .x == base::as.integer(.x)
      )
    ),
    msg = "Triage count arguments must be positive integers."
  )
  assertthat::assert_that(
    base::is.numeric(source_factor_relative_tolerance),
    base::length(source_factor_relative_tolerance) == 1L,
    base::is.finite(source_factor_relative_tolerance),
    source_factor_relative_tolerance >= 0,
    source_factor_relative_tolerance < 1,
    msg = "Source-factor tolerance must be finite in [0, 1)."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_candidate_recommendations[["candidate_id"]]
    ),
    msg = "Candidate recommendations must contain unique candidates."
  )

  vec_approved_candidate_ids <-
    data_approved_decisions |>
    dplyr::filter(.data[["review_status"]] == "approved") |>
    dplyr::pull(.data[["candidate_id"]]) |>
    base::unique()
  data_candidates_pending <-
    data_candidate_recommendations |>
    dplyr::filter(
      !.data[["candidate_id"]] %in% vec_approved_candidate_ids
    )
  vec_pending_candidate_ids <-
    data_candidates_pending[["candidate_id"]]

  data_adjudications_completed <-
    data_agent_adjudications |>
    dplyr::filter(
      .data[["review_role"]] == "adjudicator",
      .data[["recommendation"]] %in%
        base::c("none", "insufficient_evidence"),
      .data[["candidate_id"]] %in% vec_pending_candidate_ids
    )
  if (
    base::anyDuplicated(
      data_adjudications_completed[["candidate_id"]]
    ) > 0L
  ) {
    cli::cli_abort(
      "Completed adjudications must contain at most one row per candidate."
    )
  }
  vec_completed_candidate_ids <-
    data_adjudications_completed[["candidate_id"]]

  data_invalid_memberships <-
    data_record_evidence |>
    dplyr::filter(
      .data[["candidate_id"]] %in% vec_pending_candidate_ids
    ) |>
    dplyr::mutate(
      invalid_type = dplyr::case_when(
        base::is.nan(.data[["trait_value"]]) ~ "nonfinite",
        base::is.na(.data[["trait_value"]]) ~ NA_character_,
        !base::is.finite(.data[["trait_value"]]) ~ "nonfinite",
        .data[["trait_value"]] < 0 ~ "negative",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!base::is.na(.data[["invalid_type"]])) |>
    dplyr::mutate(
      pattern_reference = stringr::str_c(
        .data[["trait_domain_name"]],
        dplyr::coalesce(
          base::as.character(.data[["dataset_id"]]),
          "<missing>"
        ),
        dplyr::coalesce(.data[["dataset_name"]], "<missing>"),
        dplyr::coalesce(.data[["trait_name"]], "<missing>"),
        .data[["invalid_type"]],
        sep = "|"
      ),
      agent_group_id = purrr::map_chr(
        stringr::str_c(
          "invalid_source",
          .data[["pattern_reference"]],
          sep = "|"
        ),
        ~ digest::digest(
          .x,
          algo = "sha256",
          serialize = FALSE
        )
      ),
      group_kind = "invalid_source"
    ) |>
    dplyr::select(
      "candidate_id",
      "agent_group_id",
      "group_kind",
      "trait_domain_name",
      "pattern_reference"
    ) |>
    dplyr::distinct()

  data_recovered_memberships <-
    data_proposal_diagnostics |>
    dplyr::filter(
      .data[["candidate_id"]] %in% vec_pending_candidate_ids,
      !.data[["candidate_id"]] %in% vec_completed_candidate_ids,
      .data[["proposal_match_status"]] == "matched_selector"
    ) |>
    dplyr::mutate(
      pattern_reference = stringr::str_c(
        .data[["trait_domain_name"]],
        dplyr::coalesce(.data[["trait_name"]], "<all>"),
        dplyr::coalesce(
          base::as.character(.data[["dataset_id"]]),
          "<all>"
        ),
        dplyr::coalesce(
          base::as.character(.data[["value_lower"]]),
          "<none>"
        ),
        dplyr::coalesce(
          base::as.character(.data[["value_lower_inclusive"]]),
          "<none>"
        ),
        dplyr::coalesce(
          base::as.character(.data[["value_upper"]]),
          "<none>"
        ),
        dplyr::coalesce(
          base::as.character(.data[["value_upper_inclusive"]]),
          "<none>"
        ),
        .data[["action"]],
        dplyr::coalesce(
          base::as.character(.data[["scale_factor"]]),
          "<none>"
        ),
        sep = "|"
      ),
      agent_group_id = purrr::map_chr(
        stringr::str_c(
          "recovered_rule",
          .data[["pattern_reference"]],
          sep = "|"
        ),
        ~ digest::digest(
          .x,
          algo = "sha256",
          serialize = FALSE
        )
      ),
      group_kind = "recovered_rule"
    ) |>
    dplyr::select(
      "candidate_id",
      "agent_group_id",
      "group_kind",
      "trait_domain_name",
      "pattern_reference"
    ) |>
    dplyr::distinct()

  data_source_summaries <-
    data_dataset_evidence |>
    dplyr::filter(
      .data[["candidate_id"]] %in% vec_pending_candidate_ids,
      !.data[["candidate_id"]] %in% vec_completed_candidate_ids,
      base::is.finite(.data[["source_median"]]),
      .data[["source_median"]] > 0
    ) |>
    dplyr::select(
      "candidate_id",
      "trait_domain_name",
      "dataset_id",
      "dataset_name",
      "trait_name",
      "source_median"
    ) |>
    dplyr::distinct()
  data_source_lows <-
    data_source_summaries |>
    dplyr::arrange(
      .data[["candidate_id"]],
      .data[["trait_domain_name"]],
      .data[["source_median"]],
      .data[["dataset_id"]],
      .data[["trait_name"]]
    ) |>
    dplyr::group_by(
      .data[["candidate_id"]],
      .data[["trait_domain_name"]]
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::ungroup() |>
    dplyr::rename(
      low_dataset_id = "dataset_id",
      low_dataset_name = "dataset_name",
      low_trait_name = "trait_name",
      low_source_median = "source_median"
    )
  data_source_highs <-
    data_source_summaries |>
    dplyr::arrange(
      .data[["candidate_id"]],
      .data[["trait_domain_name"]],
      dplyr::desc(.data[["source_median"]]),
      .data[["dataset_id"]],
      .data[["trait_name"]]
    ) |>
    dplyr::group_by(
      .data[["candidate_id"]],
      .data[["trait_domain_name"]]
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::ungroup() |>
    dplyr::rename(
      high_dataset_id = "dataset_id",
      high_dataset_name = "dataset_name",
      high_trait_name = "trait_name",
      high_source_median = "source_median"
    )
  vec_source_factors <- base::c(10, 100, 1000)
  data_source_pairs <-
    data_source_lows |>
    dplyr::inner_join(
      data_source_highs,
      by = dplyr::join_by(
        candidate_id,
        trait_domain_name
      ),
      relationship = "one-to-one"
    ) |>
    dplyr::filter(
      .data[["low_source_median"]] <
        .data[["high_source_median"]]
    ) |>
    dplyr::mutate(
      source_median_ratio =
        .data[["high_source_median"]] /
        .data[["low_source_median"]],
      unit_factor = purrr::map_dbl(
        .data[["source_median_ratio"]],
        ~ vec_source_factors[[
          base::which.min(
            base::abs(base::log(.x / vec_source_factors))
          )
        ]]
      ),
      unit_factor_relative_error = base::abs(
        .data[["source_median_ratio"]] /
          .data[["unit_factor"]] -
          1
      )
    ) |>
    dplyr::filter(
      .data[["unit_factor_relative_error"]] <=
        source_factor_relative_tolerance
    )
  data_source_pattern_groups <-
    data_source_pairs |>
    dplyr::group_by(
      .data[["trait_domain_name"]],
      .data[["low_dataset_id"]],
      .data[["low_dataset_name"]],
      .data[["low_trait_name"]],
      .data[["high_dataset_id"]],
      .data[["high_dataset_name"]],
      .data[["high_trait_name"]],
      .data[["unit_factor"]]
    ) |>
    dplyr::summarise(
      n_pattern_candidates =
        dplyr::n_distinct(.data[["candidate_id"]]),
      median_source_ratio =
        stats::median(.data[["source_median_ratio"]]),
      .groups = "drop"
    ) |>
    dplyr::filter(
      .data[["n_pattern_candidates"]] >=
        base::as.integer(min_source_pattern_candidates)
    ) |>
    dplyr::mutate(
      pattern_reference = stringr::str_c(
        .data[["trait_domain_name"]],
        dplyr::coalesce(
          base::as.character(.data[["low_dataset_id"]]),
          "<missing>"
        ),
        dplyr::coalesce(.data[["low_dataset_name"]], "<missing>"),
        dplyr::coalesce(.data[["low_trait_name"]], "<missing>"),
        dplyr::coalesce(
          base::as.character(.data[["high_dataset_id"]]),
          "<missing>"
        ),
        dplyr::coalesce(.data[["high_dataset_name"]], "<missing>"),
        dplyr::coalesce(.data[["high_trait_name"]], "<missing>"),
        .data[["unit_factor"]],
        sep = "|"
      ),
      agent_group_id = purrr::map_chr(
        stringr::str_c(
          "source_pattern",
          .data[["pattern_reference"]],
          sep = "|"
        ),
        ~ digest::digest(
          .x,
          algo = "sha256",
          serialize = FALSE
        )
      ),
      group_kind = "source_pattern"
    )
  data_source_memberships <-
    data_source_pairs |>
    dplyr::inner_join(
      data_source_pattern_groups |>
        dplyr::select(
          "agent_group_id",
          "group_kind",
          "trait_domain_name",
          "low_dataset_id",
          "low_dataset_name",
          "low_trait_name",
          "high_dataset_id",
          "high_dataset_name",
          "high_trait_name",
          "unit_factor",
          "pattern_reference"
        ),
      by = dplyr::join_by(
        trait_domain_name,
        low_dataset_id,
        low_dataset_name,
        low_trait_name,
        high_dataset_id,
        high_dataset_name,
        high_trait_name,
        unit_factor
      ),
      relationship = "many-to-one"
    ) |>
    dplyr::select(
      "candidate_id",
      "agent_group_id",
      "group_kind",
      "trait_domain_name",
      "pattern_reference"
    ) |>
    dplyr::distinct()

  data_exception_memberships <-
    base::list(
      data_invalid_memberships,
      data_recovered_memberships,
      data_source_memberships
    ) |>
    purrr::list_rbind() |>
    dplyr::distinct()
  data_candidate_exception_flags <-
    data_exception_memberships |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      has_invalid_values =
        base::any(.data[["group_kind"]] == "invalid_source"),
      has_recovered_rule =
        base::any(.data[["group_kind"]] == "recovered_rule"),
      has_source_pattern =
        base::any(.data[["group_kind"]] == "source_pattern"),
      .groups = "drop"
    )

  data_candidate_triage <-
    data_candidates_pending |>
    dplyr::left_join(
      data_candidate_exception_flags,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(
          base::c(
            "has_invalid_values",
            "has_recovered_rule",
            "has_source_pattern"
          )
        ),
        ~ tidyr::replace_na(.x, FALSE)
      ),
      has_completed_investigation =
        .data[["candidate_id"]] %in% vec_completed_candidate_ids,
      triage_outcome = dplyr::case_when(
        .data[["has_invalid_values"]] ~ "agent_invalid_values",
        .data[["has_completed_investigation"]] ~
          "propose_none_completed_investigation",
        .data[["has_recovered_rule"]] ~ "agent_recovered_rule",
        .data[["has_source_pattern"]] ~
          "agent_repeated_source_pattern",
        TRUE ~ "propose_none_no_repeated_error_evidence"
      ),
      requires_agent = stringr::str_starts(
        .data[["triage_outcome"]],
        "agent_"
      ),
      propose_none = !.data[["requires_agent"]],
      triage_rationale = dplyr::case_when(
        .data[["triage_outcome"]] == "agent_invalid_values" ~
          "Negative or non-finite records require source-level review.",
        .data[["triage_outcome"]] ==
          "propose_none_completed_investigation" ~
          stringr::str_c(
            "Completed adjudication found no supported correction; ",
            "the conservative policy resolves this candidate to none."
          ),
        .data[["triage_outcome"]] == "agent_recovered_rule" ~
          "A recovered atomic selector matches current records.",
        .data[["triage_outcome"]] ==
          "agent_repeated_source_pattern" ~
          stringr::str_c(
            "At least three candidates share a source-specific factor ",
            "pattern that warrants grouped investigation."
          ),
        TRUE ~
          stringr::str_c(
            "Structured checks found no invalid records, matched ",
            "recovered rule, or repeated source-factor pattern."
          )
      )
    )

  data_none_proposals <-
    data_candidate_triage |>
    dplyr::filter(.data[["propose_none"]]) |>
    dplyr::mutate(
      decision_key = stringr::str_c(
        .data[["candidate_id"]],
        "none",
        "programmatic_triage_v1",
        sep = "|"
      ),
      decision_id = purrr::map_chr(
        .data[["decision_key"]],
        ~ digest::digest(
          .x,
          algo = "sha256",
          serialize = FALSE
        )
      ),
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = NA_real_,
      value_upper_inclusive = NA,
      action = "none",
      scale_factor = NA_real_,
      rationale = .data[["triage_rationale"]],
      evidence_reference = evidence_reference,
      source_reference = stringr::str_c(
        "programmatic_triage:",
        .data[["candidate_id"]]
      ),
      review_status = "proposed",
      reviewer = NA_character_,
      reviewed_at = NA_character_
    ) |>
    dplyr::select(
      "decision_id",
      "candidate_id",
      "taxon_name",
      "trait_domain_name",
      "trait_name",
      "dataset_id",
      "value_lower",
      "value_lower_inclusive",
      "value_upper",
      "value_upper_inclusive",
      "action",
      "scale_factor",
      "rationale",
      "evidence_reference",
      "source_reference",
      "review_status",
      "reviewer",
      "reviewed_at"
    )

  data_exception_rows <-
    data_exception_memberships |>
    dplyr::inner_join(
      data_candidate_triage |>
        dplyr::filter(.data[["requires_agent"]]) |>
        dplyr::select(
          "candidate_id",
          "candidate_impact_score",
          "n_records_current"
        ),
      by = dplyr::join_by(candidate_id),
      relationship = "many-to-one"
    )
  if (
    base::nrow(data_exception_rows) == 0L
  ) {
    data_exception_groups <-
      tibble::tibble(
        agent_group_id = character(),
        group_kind = character(),
        trait_domain_name = character(),
        pattern_reference = character(),
        n_candidates = integer(),
        n_records = integer(),
        maximum_candidate_impact = double(),
        candidate_ids = character()
      )
  } else {
    data_exception_groups <-
      data_exception_rows |>
      dplyr::group_by(
        .data[["agent_group_id"]],
        .data[["group_kind"]],
        .data[["trait_domain_name"]],
        .data[["pattern_reference"]]
      ) |>
      dplyr::summarise(
        n_candidates = dplyr::n_distinct(.data[["candidate_id"]]),
        n_records = base::sum(.data[["n_records_current"]]),
        maximum_candidate_impact =
          base::max(.data[["candidate_impact_score"]]),
        candidate_ids = stringr::str_c(
          base::sort(base::unique(.data[["candidate_id"]])),
          collapse = ";"
        ),
        .groups = "drop"
      )
  }
  data_agent_group_queue <-
    data_exception_groups |>
    dplyr::mutate(
      agent_priority = dplyr::case_when(
        .data[["group_kind"]] == "invalid_source" ~ 1L,
        .data[["group_kind"]] == "recovered_rule" ~ 2L,
        TRUE ~ 3L
      )
    ) |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    dplyr::arrange(
      .data[["agent_priority"]],
      dplyr::desc(.data[["maximum_candidate_impact"]]),
      .data[["agent_group_id"]],
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      agent_group_order = dplyr::row_number(),
      agent_batch_number = base::as.integer(
        base::ceiling(
          .data[["agent_group_order"]] /
            base::as.integer(agent_groups_per_batch)
        )
      ),
      domain_slug = stringr::str_replace_all(
        stringr::str_to_lower(.data[["trait_domain_name"]]),
        "[^a-z0-9]+",
        "_"
      ),
      agent_batch_id = stringr::str_c(
        .data[["domain_slug"]],
        "triage",
        stringr::str_pad(
          .data[["agent_batch_number"]],
          width = 2L,
          pad = "0"
        ),
        sep = "_"
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-"domain_slug")

  data_triage_summary <-
    data_candidate_triage |>
    dplyr::count(
      .data[["trait_domain_name"]],
      .data[["triage_outcome"]],
      name = "n_candidates"
    ) |>
    dplyr::arrange(
      .data[["trait_domain_name"]],
      .data[["triage_outcome"]]
    )
  n_initial_agent_batches <-
    dplyr::n_distinct(data_agent_group_queue[["agent_batch_id"]])
  data_cost_gate <-
    tibble::tibble(
      n_pending_candidates = base::nrow(data_candidate_triage),
      n_none_proposals = base::nrow(data_none_proposals),
      n_agent_candidates = base::sum(
        data_candidate_triage[["requires_agent"]]
      ),
      n_agent_groups = base::nrow(data_exception_groups),
      n_initial_agent_batches = n_initial_agent_batches,
      n_initial_agent_runs = n_initial_agent_batches,
      n_previous_style_runs = 3L * n_initial_agent_batches,
      min_source_pattern_candidates =
        base::as.integer(min_source_pattern_candidates),
      source_factor_relative_tolerance =
        source_factor_relative_tolerance,
      agent_groups_per_batch =
        base::as.integer(agent_groups_per_batch)
    )

  res <-
    base::list(
      data_candidate_triage = data_candidate_triage,
      data_none_proposals = data_none_proposals,
      data_exception_memberships = data_exception_memberships,
      data_exception_groups = data_exception_groups,
      data_agent_group_queue = data_agent_group_queue,
      data_source_pairs = data_source_pairs,
      data_triage_summary = data_triage_summary,
      data_cost_gate = data_cost_gate
    )
  return(res)
}

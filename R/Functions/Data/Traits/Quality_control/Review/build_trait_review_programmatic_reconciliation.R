#' @title Reconcile Programmatic Trait Review Candidates
#' @description
#' Applies conservative deterministic checks to pending trait-review
#' candidates. It proposes rules only for obsolete candidates, independently
#' corroborated dataset factors, or threshold rules that improve current
#' within-candidate agreement. Other candidates remain pending or are routed
#' to targeted agent review.
#' @param data_candidate_triage
#' Candidate triage from [build_trait_review_programmatic_triage()].
#' @param data_source_pairs
#' Candidate source-pair evidence from the programmatic triage.
#' @param data_submission_audit
#' Derived review-submission audit containing the archived instructions.
#' @param data_record_evidence
#' Current record evidence from [build_trait_review_evidence_packets()].
#' @param evidence_reference
#' Non-empty path to the human-readable reconciliation report.
#' @return
#' A named list containing one reconciliation row per pending candidate,
#' unapproved decision proposals, and an outcome summary.
#' @export
build_trait_review_programmatic_reconciliation <- function(
    data_candidate_triage,
    data_source_pairs,
    data_submission_audit,
    data_record_evidence,
    evidence_reference) {
  list_inputs <-
    base::list(
      candidates = data_candidate_triage,
      source_pairs = data_source_pairs,
      submission = data_submission_audit,
      records = data_record_evidence
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All programmatic-reconciliation inputs must be data frames."
  )
  list_required_columns <-
    base::list(
      candidates = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "triage_outcome",
        "n_records_current",
        "pending_programmatic"
      ),
      source_pairs = base::c(
        "candidate_id",
        "trait_domain_name",
        "low_dataset_id",
        "low_trait_name",
        "high_dataset_id",
        "high_trait_name",
        "unit_factor",
        "unit_factor_relative_error"
      ),
      submission = base::c(
        "candidate_id",
        "action_source",
        "scale_factor_source",
        "notes_lower",
        "source_row"
      ),
      records = base::c(
        "candidate_id",
        "dataset_id",
        "trait_name",
        "trait_value"
      )
    )
  vec_missing_columns <-
    purrr::imap_chr(
      list_required_columns,
      function(vec_required, input_name) {
        base::setdiff(
          vec_required,
          base::names(list_inputs[[input_name]])
        ) |>
          stringr::str_c(collapse = ",")
      }
    )
  assertthat::assert_that(
    base::all(vec_missing_columns == ""),
    msg = "Programmatic-reconciliation inputs are missing required columns."
  )
  assertthat::assert_that(
    base::is.character(evidence_reference),
    base::length(evidence_reference) == 1L,
    !base::is.na(evidence_reference),
    base::nzchar(evidence_reference),
    msg = "evidence_reference must be one non-empty path."
  )

  data_candidates <-
    data_candidate_triage |>
    dplyr::filter(.data[["pending_programmatic"]])
  assertthat::assert_that(
    !base::anyDuplicated(data_candidates[["candidate_id"]]),
    !base::anyDuplicated(data_source_pairs[["candidate_id"]]),
    msg = "Candidate and source-pair identifiers must be unique."
  )

  threshold_pattern <-
    stringr::str_c(
      "^rescale values (below|above) ",
      "([0-9]+(?:[.][0-9]+)?) only$"
    )
  data_submission_summary <-
    data_submission_audit |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_instruction_rows = dplyr::n(),
      action_source = dplyr::first(.data[["action_source"]]),
      scale_factor_source = dplyr::first(
        .data[["scale_factor_source"]]
      ),
      notes_lower = dplyr::first(.data[["notes_lower"]]),
      source_rows = stringr::str_c(
        base::sort(base::unique(.data[["source_row"]])),
        collapse = ";"
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      submitted_scale_factor = readr::parse_double(
        base::as.character(.data[["scale_factor_source"]]),
        na = base::c("", "NA", "x", "e"),
        locale = readr::locale(decimal_mark = ".")
      ),
      threshold_direction = stringr::str_match(
        .data[["notes_lower"]],
        threshold_pattern
      )[, 2L],
      threshold_value = base::as.numeric(
        stringr::str_match(
          .data[["notes_lower"]],
          threshold_pattern
        )[, 3L]
      )
    )

  data_threshold_rules <-
    data_submission_summary |>
    dplyr::filter(
      .data[["n_instruction_rows"]] == 1L,
      .data[["action_source"]] == "scale",
      base::is.finite(.data[["submitted_scale_factor"]]),
      .data[["submitted_scale_factor"]] > 0,
      !base::is.na(.data[["threshold_direction"]]),
      base::is.finite(.data[["threshold_value"]])
    ) |>
    dplyr::select(
      "candidate_id",
      "submitted_scale_factor",
      "threshold_direction",
      "threshold_value"
    )
  data_threshold_checks <-
    data_record_evidence |>
    dplyr::inner_join(
      data_threshold_rules,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::filter(
      base::is.finite(.data[["trait_value"]]),
      .data[["trait_value"]] > 0
    ) |>
    dplyr::mutate(
      selected = dplyr::if_else(
        .data[["threshold_direction"]] == "below",
        .data[["trait_value"]] < .data[["threshold_value"]],
        .data[["trait_value"]] > .data[["threshold_value"]]
      )
    ) |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_selected = base::sum(.data[["selected"]]),
      n_unselected = base::sum(!.data[["selected"]]),
      selected_median = stats::median(
        .data[["trait_value"]][.data[["selected"]]]
      ),
      unselected_median = stats::median(
        .data[["trait_value"]][!.data[["selected"]]]
      ),
      .groups = "drop"
    ) |>
    dplyr::left_join(
      data_threshold_rules,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::mutate(
      threshold_gap_before = base::abs(
        base::log10(
          .data[["selected_median"]] /
            .data[["unselected_median"]]
        )
      ),
      threshold_gap_after = base::abs(
        base::log10(
          .data[["selected_median"]] *
            .data[["submitted_scale_factor"]] /
            .data[["unselected_median"]]
        )
      ),
      threshold_validated =
        .data[["n_selected"]] >= 2L &
        .data[["n_unselected"]] >= 2L &
        .data[["threshold_gap_before"]] >= 0.7 &
        .data[["threshold_gap_after"]] <= 0.3 &
        .data[["threshold_gap_before"]] -
          .data[["threshold_gap_after"]] >= 0.5
    )

  data_source_counts <-
    data_record_evidence |>
    dplyr::filter(
      base::is.finite(.data[["trait_value"]]),
      .data[["trait_value"]] > 0
    ) |>
    dplyr::count(
      .data[["candidate_id"]],
      .data[["dataset_id"]],
      .data[["trait_name"]],
      name = "n_source_records"
    )
  data_source_checks <-
    data_source_pairs |>
    dplyr::left_join(
      data_submission_summary,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_source_counts |>
        dplyr::rename(
          low_dataset_id = "dataset_id",
          low_trait_name = "trait_name",
          n_low_records = "n_source_records"
        ),
      by = dplyr::join_by(
        candidate_id,
        low_dataset_id,
        low_trait_name
      )
    ) |>
    dplyr::left_join(
      data_source_counts |>
        dplyr::rename(
          high_dataset_id = "dataset_id",
          high_trait_name = "trait_name",
          n_high_records = "n_source_records"
        ),
      by = dplyr::join_by(
        candidate_id,
        high_dataset_id,
        high_trait_name
      )
    ) |>
    dplyr::mutate(
      scale_low_source =
        base::abs(
          base::log10(
            .data[["submitted_scale_factor"]] /
              .data[["unit_factor"]]
          )
        ) < 1e-8,
      scale_high_source =
        base::abs(
          base::log10(
            .data[["submitted_scale_factor"]] *
              .data[["unit_factor"]]
          )
        ) < 1e-8,
      source_factor_validated =
        .data[["n_instruction_rows"]] == 1L &
        .data[["action_source"]] == "scale" &
        .data[["notes_lower"]] == "x" &
        base::is.finite(.data[["submitted_scale_factor"]]) &
        .data[["unit_factor_relative_error"]] <= 0.05 &
        tidyr::replace_na(.data[["n_low_records"]], 0L) >= 2L &
        tidyr::replace_na(.data[["n_high_records"]], 0L) >= 2L &
        (.data[["scale_low_source"]] |
          .data[["scale_high_source"]]),
      source_pattern_strong =
        .data[["unit_factor_relative_error"]] <= 0.05
    )

  data_candidate_reconciliation <-
    data_candidates |>
    dplyr::left_join(
      data_submission_summary,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_threshold_checks |>
        dplyr::select(
          "candidate_id",
          "n_selected",
          "n_unselected",
          "threshold_gap_before",
          "threshold_gap_after",
          "threshold_validated"
        ),
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_source_checks |>
        dplyr::select(
          "candidate_id",
          "source_factor_validated",
          "source_pattern_strong",
          "scale_low_source",
          "scale_high_source",
          "n_low_records",
          "n_high_records"
        ),
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::mutate(
      n_instruction_rows = tidyr::replace_na(
        .data[["n_instruction_rows"]],
        0L
      ),
      threshold_rule_parsed =
        !base::is.na(.data[["threshold_direction"]]),
      threshold_validated = tidyr::replace_na(
        .data[["threshold_validated"]],
        FALSE
      ),
      source_factor_validated = tidyr::replace_na(
        .data[["source_factor_validated"]],
        FALSE
      ),
      source_pattern_strong = tidyr::replace_na(
        .data[["source_pattern_strong"]],
        FALSE
      ),
      reconciliation_outcome = dplyr::case_when(
        .data[["n_records_current"]] == 0L ~
          "propose_none_no_current_records",
        .data[["threshold_validated"]] ~
          "propose_scale_validated_threshold",
        .data[["source_factor_validated"]] ~
          "propose_scale_corroborated_source",
        .data[["threshold_rule_parsed"]] ~
          "agent_threshold_rule_not_corroborated",
        .data[["n_instruction_rows"]] > 1L ~
          "agent_conflicting_submitted_instructions",
        .data[["triage_outcome"]] ==
          "pending_recovered_proposal" ~
          "agent_unmatched_recovered_rule",
        .data[["triage_outcome"]] ==
          "pending_historical_drift" ~
          "agent_historical_drift",
        .data[["action_source"]] == "exclude" ~
          "agent_unparsed_exclusion_instruction",
        .data[["source_pattern_strong"]] ~
          "agent_strong_isolated_source_pattern",
        TRUE ~ .data[["triage_outcome"]]
      ),
      requires_agent = stringr::str_starts(
        .data[["reconciliation_outcome"]],
        "agent_"
      ),
      propose_rule = stringr::str_starts(
        .data[["reconciliation_outcome"]],
        "propose_"
      ),
      remains_pending = !.data[["requires_agent"]] &
        !.data[["propose_rule"]]
    )

  data_none_proposals <-
    data_candidate_reconciliation |>
    dplyr::filter(
      .data[["reconciliation_outcome"]] ==
        "propose_none_no_current_records"
    ) |>
    dplyr::transmute(
      candidate_id = .data[["candidate_id"]],
      taxon_name = .data[["taxon_name"]],
      trait_domain_name = .data[["trait_domain_name"]],
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = NA_real_,
      value_upper_inclusive = NA,
      action = "none",
      scale_factor = NA_real_,
      rationale = "No current trait record exists for this candidate."
    )
  data_threshold_proposals <-
    data_candidate_reconciliation |>
    dplyr::filter(.data[["threshold_validated"]]) |>
    dplyr::transmute(
      candidate_id = .data[["candidate_id"]],
      taxon_name = .data[["taxon_name"]],
      trait_domain_name = .data[["trait_domain_name"]],
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = dplyr::if_else(
        .data[["threshold_direction"]] == "above",
        .data[["threshold_value"]],
        NA_real_
      ),
      value_lower_inclusive = dplyr::if_else(
        .data[["threshold_direction"]] == "above",
        FALSE,
        NA
      ),
      value_upper = dplyr::if_else(
        .data[["threshold_direction"]] == "below",
        .data[["threshold_value"]],
        NA_real_
      ),
      value_upper_inclusive = dplyr::if_else(
        .data[["threshold_direction"]] == "below",
        FALSE,
        NA
      ),
      action = "scale",
      scale_factor = .data[["submitted_scale_factor"]],
      rationale = stringr::str_c(
        "The submitted threshold rule reduced the current log-median ",
        "gap from ",
        base::round(.data[["threshold_gap_before"]], 3L),
        " to ",
        base::round(.data[["threshold_gap_after"]], 3L),
        "."
      )
    )
  data_source_proposals <-
    data_candidate_reconciliation |>
    dplyr::filter(.data[["source_factor_validated"]]) |>
    dplyr::inner_join(
      data_source_checks,
      by = dplyr::join_by(candidate_id),
      suffix = base::c("", "_source")
    ) |>
    dplyr::transmute(
      candidate_id = .data[["candidate_id"]],
      taxon_name = .data[["taxon_name"]],
      trait_domain_name = .data[["trait_domain_name"]],
      trait_name = dplyr::if_else(
        .data[["scale_low_source"]],
        .data[["low_trait_name"]],
        .data[["high_trait_name"]]
      ),
      dataset_id = base::as.integer(
        dplyr::if_else(
          .data[["scale_low_source"]],
          .data[["low_dataset_id"]],
          .data[["high_dataset_id"]]
        )
      ),
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = NA_real_,
      value_upper_inclusive = NA,
      action = "scale",
      scale_factor = .data[["submitted_scale_factor"]],
      rationale = stringr::str_c(
        "The submitted factor matches an independent current source ",
        "median ratio within 5%."
      )
    )
  data_decision_proposals <-
    dplyr::bind_rows(
      data_none_proposals,
      data_source_proposals,
      data_threshold_proposals
    ) |>
    dplyr::mutate(
      decision_key = stringr::str_c(
        .data[["candidate_id"]],
        .data[["action"]],
        tidyr::replace_na(
          base::as.character(.data[["dataset_id"]]),
          ""
        ),
        tidyr::replace_na(.data[["trait_name"]], ""),
        tidyr::replace_na(
          base::as.character(.data[["value_lower"]]),
          ""
        ),
        tidyr::replace_na(
          base::as.character(.data[["value_upper"]]),
          ""
        ),
        tidyr::replace_na(
          base::as.character(.data[["scale_factor"]]),
          ""
        ),
        "programmatic_reconciliation_v1",
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
      evidence_reference = evidence_reference,
      source_reference = stringr::str_c(
        "programmatic_reconciliation:",
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
  data_summary <-
    data_candidate_reconciliation |>
    dplyr::count(
      .data[["trait_domain_name"]],
      .data[["reconciliation_outcome"]],
      name = "n_candidates"
    )
  data_proposal_audit <-
    data_decision_proposals |>
    dplyr::left_join(
      data_candidate_reconciliation |>
        dplyr::select(
          "candidate_id",
          "reconciliation_outcome",
          "n_selected",
          "n_low_records",
          "n_high_records",
          "scale_low_source",
          "threshold_gap_before",
          "threshold_gap_after"
        ),
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::mutate(
      proposed_record_count = dplyr::case_when(
        .data[["action"]] == "none" ~ 0L,
        .data[["reconciliation_outcome"]] ==
          "propose_scale_validated_threshold" ~
          base::as.integer(.data[["n_selected"]]),
        .data[["scale_low_source"]] %in% TRUE ~
          base::as.integer(.data[["n_low_records"]]),
        TRUE ~ base::as.integer(.data[["n_high_records"]])
      )
    ) |>
    dplyr::select(
      "decision_id",
      "candidate_id",
      "action",
      "reconciliation_outcome",
      "proposed_record_count",
      "threshold_gap_before",
      "threshold_gap_after"
    )

  assertthat::assert_that(
    base::nrow(data_candidate_reconciliation) ==
      base::nrow(data_candidates),
    !base::anyDuplicated(
      data_candidate_reconciliation[["candidate_id"]]
    ),
    !base::anyDuplicated(data_decision_proposals[["decision_id"]]),
    msg = "Programmatic reconciliation must preserve unique candidates."
  )

  return(
    base::list(
      data_candidate_reconciliation =
        data_candidate_reconciliation,
      data_decision_proposals = data_decision_proposals,
      data_proposal_audit = data_proposal_audit,
      data_reconciliation_summary = data_summary
    )
  )
}

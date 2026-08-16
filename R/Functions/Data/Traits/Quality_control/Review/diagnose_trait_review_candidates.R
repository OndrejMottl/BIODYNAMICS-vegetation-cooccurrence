#' @title Diagnose Trait Review Candidates
#' @description
#' Produces conservative policy recommendations, targeted investigations, and
#' exact recovered-proposal diagnostics without changing records or decisions.
#' @param data_candidate_evidence
#' Candidate evidence returned by [build_trait_review_evidence_packets()].
#' @param data_record_evidence
#' Record evidence returned by [build_trait_review_evidence_packets()].
#' @param data_review_decision_proposals
#' Recovered, unapproved atomic decision proposals.
#' @return
#' A named list containing `data_candidate_recommendations` and
#' `data_proposal_diagnostics`.
#' @examples
#' candidate_evidence <- tibble::tibble(
#'   candidate_id = "candidate-a",
#'   n_nonpositive = 0L,
#'   n_nonfinite = 0L,
#'   historical_summary_stable = TRUE,
#'   implicit_none_proposal_eligible = TRUE,
#'   possible_unit_pattern = FALSE,
#'   candidate_impact_score = 0.5,
#'   candidate_impact_tier = "medium"
#' )
#' record_evidence <- tibble::tibble(
#'   candidate_id = "candidate-a",
#'   taxon_name = "Taxon A",
#'   trait_domain_name = "Diaspore mass",
#'   trait_value = 1,
#'   trait_name = "Seed mass",
#'   dataset_id = 1L
#' )
#' proposals <- tibble::tibble(
#'   decision_id = character(),
#'   candidate_id = character(),
#'   taxon_name = character(),
#'   trait_domain_name = character(),
#'   trait_name = character(),
#'   dataset_id = integer(),
#'   value_lower = double(),
#'   value_lower_inclusive = logical(),
#'   value_upper = double(),
#'   value_upper_inclusive = logical(),
#'   action = character(),
#'   scale_factor = double()
#' )
#' diagnose_trait_review_candidates(
#'   candidate_evidence,
#'   record_evidence,
#'   proposals
#' )
#' @export
diagnose_trait_review_candidates <- function(
    data_candidate_evidence,
    data_record_evidence,
    data_review_decision_proposals) {
  list_inputs <-
    base::list(
      candidates = data_candidate_evidence,
      records = data_record_evidence,
      proposals = data_review_decision_proposals
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All candidate-diagnosis inputs must be data frames."
  )
  list_required_columns <-
    base::list(
      candidates = base::c(
        "candidate_id",
        "n_nonpositive",
        "n_nonfinite",
        "historical_summary_stable",
        "implicit_none_proposal_eligible",
        "possible_unit_pattern",
        "candidate_impact_score",
        "candidate_impact_tier"
      ),
      records = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "trait_value",
        "trait_name",
        "dataset_id"
      ),
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
        "scale_factor"
      )
    )
  vec_has_required_columns <-
    purrr::imap_lgl(
      list_required_columns,
      function(vec_required, input_name) {
        base::all(vec_required %in% base::names(list_inputs[[input_name]]))
      }
    )
  assertthat::assert_that(
    base::all(vec_has_required_columns),
    msg = "Candidate-diagnosis inputs are missing required columns."
  )
  assertthat::assert_that(
    !base::anyDuplicated(data_candidate_evidence[["candidate_id"]]),
    !base::anyDuplicated(data_review_decision_proposals[["decision_id"]]),
    msg = "Candidate and proposal identifiers must be unique."
  )

  list_proposal_diagnostics <-
    base::vector(
      mode = "list",
      length = base::nrow(data_review_decision_proposals)
    )
  for (
    index_proposal in
      base::seq_len(base::nrow(data_review_decision_proposals))
  ) {
    proposal <-
      data_review_decision_proposals[index_proposal, , drop = FALSE]
    is_match <-
      data_record_evidence[["candidate_id"]] ==
        proposal[["candidate_id"]][[1L]] &
      data_record_evidence[["taxon_name"]] ==
        proposal[["taxon_name"]][[1L]] &
      data_record_evidence[["trait_domain_name"]] ==
        proposal[["trait_domain_name"]][[1L]]

    trait_name <- proposal[["trait_name"]][[1L]]
    if (
      !base::is.na(trait_name) && trait_name != ""
    ) {
      is_match <-
        is_match &
        data_record_evidence[["trait_name"]] == trait_name
    }
    dataset_id <- proposal[["dataset_id"]][[1L]]
    if (
      !base::is.na(dataset_id)
    ) {
      is_match <-
        is_match &
        data_record_evidence[["dataset_id"]] == dataset_id
    }
    value_lower <- proposal[["value_lower"]][[1L]]
    if (
      !base::is.na(value_lower)
    ) {
      if (
        base::isTRUE(proposal[["value_lower_inclusive"]][[1L]])
      ) {
        is_match <-
          is_match &
          data_record_evidence[["trait_value"]] >= value_lower
      } else {
        is_match <-
          is_match &
          data_record_evidence[["trait_value"]] > value_lower
      }
    }
    value_upper <- proposal[["value_upper"]][[1L]]
    if (
      !base::is.na(value_upper)
    ) {
      if (
        base::isTRUE(proposal[["value_upper_inclusive"]][[1L]])
      ) {
        is_match <-
          is_match &
          data_record_evidence[["trait_value"]] <= value_upper
      } else {
        is_match <-
          is_match &
          data_record_evidence[["trait_value"]] < value_upper
      }
    }
    is_match[base::is.na(is_match)] <- FALSE
    action <- proposal[["action"]][[1L]]
    scale_factor <- proposal[["scale_factor"]][[1L]]
    action_is_valid <- action %in% base::c("none", "exclude", "scale")
    scale_factor_is_valid <-
      action != "scale" ||
      (
        !base::is.na(scale_factor) &&
        base::is.finite(scale_factor) &&
        scale_factor > 0
      )
    n_matched_records <- base::sum(is_match)
    proposal_match_status <- dplyr::case_when(
      !action_is_valid || !scale_factor_is_valid ~ "invalid_rule",
      n_matched_records == 0L ~ "unmatched_selector",
      TRUE ~ "matched_selector"
    )

    list_proposal_diagnostics[[index_proposal]] <-
      proposal |>
      dplyr::mutate(
        n_matched_records = base::as.integer(n_matched_records),
        action_is_valid = action_is_valid,
        scale_factor_is_valid = scale_factor_is_valid,
        proposal_match_status = proposal_match_status
      )
  }

  data_proposal_diagnostics <-
    dplyr::bind_rows(list_proposal_diagnostics)
  if (
    base::nrow(data_proposal_diagnostics) == 0L
  ) {
    data_proposal_diagnostics <-
      data_review_decision_proposals |>
      dplyr::mutate(
        n_matched_records = base::integer(),
        action_is_valid = base::logical(),
        scale_factor_is_valid = base::logical(),
        proposal_match_status = base::character()
      )
  }

  data_proposal_summary <-
    data_proposal_diagnostics |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_recovered_rules = dplyr::n(),
      n_matched_rules = base::sum(
        .data[["proposal_match_status"]] == "matched_selector"
      ),
      n_unresolved_rules = base::sum(
        .data[["proposal_match_status"]] != "matched_selector"
      ),
      n_records_selected_by_proposals = base::sum(
        .data[["n_matched_records"]]
      ),
      .groups = "drop"
    )
  if (
    !"historical_scope_status" %in%
      base::names(data_candidate_evidence)
  ) {
    data_candidate_evidence <-
      data_candidate_evidence |>
      dplyr::mutate(historical_scope_status = NA_character_)
  }
  if (
    !"n_pending_submission_rows" %in%
      base::names(data_candidate_evidence)
  ) {
    data_candidate_evidence <-
      data_candidate_evidence |>
      dplyr::mutate(n_pending_submission_rows = 0L)
  }
  if (
    !"n_zero" %in% base::names(data_candidate_evidence)
  ) {
    data_candidate_evidence <-
      data_candidate_evidence |>
      dplyr::mutate(n_zero = .data[["n_nonpositive"]])
  }
  if (
    !"n_negative" %in% base::names(data_candidate_evidence)
  ) {
    data_candidate_evidence <-
      data_candidate_evidence |>
      dplyr::mutate(n_negative = 0L)
  }
  data_candidate_recommendations <-
    data_candidate_evidence |>
    dplyr::left_join(
      data_proposal_summary,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(
          base::c(
            "n_recovered_rules",
            "n_matched_rules",
            "n_unresolved_rules",
            "n_records_selected_by_proposals"
          )
        ),
        ~ base::as.integer(tidyr::replace_na(.x, 0L))
      ),
      deterministic_outcome = dplyr::case_when(
        .data[["n_nonfinite"]] > 0L |
          .data[["n_negative"]] > 0L ~
          "investigate_invalid_values",
        .data[["n_zero"]] > 0L ~
          "exclude_invalid_values",
        .data[["n_unresolved_rules"]] > 0L ~
          "investigate_recovered_proposal",
        .data[["n_matched_rules"]] > 0L ~
          "validate_recovered_proposal",
        .data[["n_pending_submission_rows"]] > 0L ~
          "investigate_submitted_note",
        .data[["historical_summary_stable"]] &
          .data[["implicit_none_proposal_eligible"]] ~
          "retain_historical_no_action",
        .data[["possible_unit_pattern"]] ~
          "investigate_unit_pattern",
        .data[["historical_scope_status"]] ==
          "confirmed_previous_review" ~
          "investigate_historical_drift",
        TRUE ~ "retain_flagged_uncertain"
      ),
      suggested_action = dplyr::case_when(
        .data[["deterministic_outcome"]] ==
          "exclude_invalid_values" ~ "exclude",
        .data[["deterministic_outcome"]] %in%
          base::c(
            "retain_historical_no_action",
            "retain_flagged_uncertain"
          ) ~ "none",
        TRUE ~ "defer"
      ),
      decision_authority = dplyr::case_when(
        .data[["deterministic_outcome"]] ==
          "exclude_invalid_values" ~ "deterministic_rule",
        .data[["deterministic_outcome"]] ==
          "retain_historical_no_action" ~ "historical_recovery",
        .data[["deterministic_outcome"]] %in%
          base::c(
            "validate_recovered_proposal",
            "investigate_recovered_proposal",
            "investigate_submitted_note"
          ) ~ "recovered_submission",
        TRUE ~ "agent_review"
      ),
      confidence = dplyr::case_when(
        .data[["deterministic_outcome"]] %in%
          base::c(
            "exclude_invalid_values",
            "retain_historical_no_action"
          ) ~ "high",
        .data[["deterministic_outcome"]] %in%
          base::c(
            "validate_recovered_proposal",
            "investigate_unit_pattern",
            "investigate_invalid_values",
            "retain_flagged_uncertain"
          ) ~ "medium",
        TRUE ~ "low"
      ),
      acceptance_eligibility = dplyr::case_when(
        .data[["deterministic_outcome"]] ==
          "exclude_invalid_values" &
          .data[["n_nonfinite"]] == 0L ~
          "eligible_policy_acceptance",
        .data[["deterministic_outcome"]] %in%
          base::c(
            "retain_historical_no_action",
            "retain_flagged_uncertain"
          ) ~ "eligible_policy_acceptance",
        TRUE ~ "requires_agent_review"
      ),
      recommendation_rationale = dplyr::case_when(
        .data[["deterministic_outcome"]] ==
          "exclude_invalid_values" ~
          "Strictly positive trait domain contains invalid values.",
        .data[["deterministic_outcome"]] ==
          "investigate_invalid_values" ~
          stringr::str_c(
            "Negative or non-finite values may indicate a source-level ",
            "transformation and require investigation."
          ),
        .data[["deterministic_outcome"]] ==
          "investigate_recovered_proposal" ~
          "At least one recovered selector is invalid or unmatched.",
        .data[["deterministic_outcome"]] ==
          "validate_recovered_proposal" ~
          "Recovered selectors match current records but need confirmation.",
        .data[["deterministic_outcome"]] ==
          "investigate_submitted_note" ~
          "A submitted concern remains unresolved and needs investigation.",
        .data[["deterministic_outcome"]] ==
          "retain_historical_no_action" ~
          "Historical no-action evidence has a stable current summary.",
        .data[["deterministic_outcome"]] ==
          "investigate_unit_pattern" ~
          "Source medians differ by a plausible unit conversion factor.",
        .data[["deterministic_outcome"]] ==
          "investigate_historical_drift" ~
          "Current summary differs from the historically reviewed summary.",
        TRUE ~
          stringr::str_c(
            "No objective error evidence supports correction; ",
            "retain under the conservative policy."
          )
      )
    )

  return(
    base::list(
      data_candidate_recommendations = data_candidate_recommendations,
      data_proposal_diagnostics = data_proposal_diagnostics
    )
  )
}

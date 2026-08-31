#' @title Build Grouped Trait Review Investigation
#' @description
#' Resolves investigated candidates without source-level support to approved
#' no-action decisions. Candidates affected by proposed source-scale rules
#' remain pending; candidates covered by approved source rules are closed as
#' requiring no additional taxon-specific action.
#' @param data_trait_review_exceptions Unresolved review candidates.
#' @param data_candidate_source_memberships Candidate-to-source memberships.
#' @param data_source_scale_proposals Proposed or approved source-scale rules.
#' @param reviewer Name of the approving human reviewer.
#' @param reviewed_at ISO review date.
#' @param evidence_reference Path to the durable investigation report.
#' @return
#' A named list containing the investigation audit, approved no-action
#' decisions, pending candidates, and an outcome summary.
#' @export
build_trait_review_grouped_investigation <- function(
    data_trait_review_exceptions,
    data_candidate_source_memberships,
    data_source_scale_proposals,
    reviewer,
    reviewed_at,
    evidence_reference) {
  list_inputs <-
    base::list(
      exceptions = data_trait_review_exceptions,
      memberships = data_candidate_source_memberships,
      proposals = data_source_scale_proposals
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All grouped-investigation inputs must be data frames."
  )
  list_required_columns <-
    base::list(
      exceptions = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name"
      ),
      memberships = base::c(
        "candidate_id",
        "trait_domain_name",
        "data_source_id"
      ),
      proposals = base::c(
        "source_scale_rule_id",
        "data_source_id",
        "trait_domain_name",
        "review_status"
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
    msg = "Grouped-investigation inputs are missing required columns."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_trait_review_exceptions[["candidate_id"]]
    ),
    !base::anyDuplicated(
      data_source_scale_proposals[
        base::c("data_source_id", "trait_domain_name")
      ]
    ),
    msg = "Exceptions and source proposals must use unique keys."
  )
  assertthat::assert_that(
    base::all(
      data_source_scale_proposals[["review_status"]] %in%
        base::c("proposed", "approved")
    ),
    msg = "Grouped source-scale rules must be proposed or approved."
  )
  assertthat::assert_that(
    base::all(
      data_candidate_source_memberships[["candidate_id"]] %in%
        data_trait_review_exceptions[["candidate_id"]]
    ),
    msg = "Candidate source memberships must identify current exceptions."
  )
  assertthat::assert_that(
    base::is.character(reviewer),
    base::length(reviewer) == 1L,
    !base::is.na(reviewer),
    base::nzchar(stringr::str_trim(reviewer)),
    msg = "reviewer must be one non-empty human reviewer name."
  )
  assertthat::assert_that(
    base::is.character(reviewed_at),
    base::length(reviewed_at) == 1L,
    stringr::str_detect(reviewed_at, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"),
    !base::is.na(base::as.Date(reviewed_at)),
    msg = "reviewed_at must be one valid ISO date."
  )
  assertthat::assert_that(
    base::is.character(evidence_reference),
    base::length(evidence_reference) == 1L,
    !base::is.na(evidence_reference),
    base::nzchar(stringr::str_trim(evidence_reference)),
    msg = "evidence_reference must be one non-empty path."
  )

  data_proposal_memberships <-
    data_candidate_source_memberships |>
    dplyr::inner_join(
      data_source_scale_proposals |>
        dplyr::select(
          "source_scale_rule_id",
          "data_source_id",
          "trait_domain_name",
          "review_status"
        ),
      by = dplyr::join_by(data_source_id, trait_domain_name),
      relationship = "many-to-one"
    ) |>
    dplyr::distinct(
      .data[["candidate_id"]],
      .data[["source_scale_rule_id"]],
      .data[["review_status"]]
    ) |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_source_rules = dplyr::n(),
      n_proposed_source_rules = base::sum(
        .data[["review_status"]] == "proposed"
      ),
      n_approved_source_rules = base::sum(
        .data[["review_status"]] == "approved"
      ),
      proposed_source_rule_ids = stringr::str_c(
        base::sort(
          .data[["source_scale_rule_id"]][
            .data[["review_status"]] == "proposed"
          ]
        ),
        collapse = ";"
      ),
      approved_source_rule_ids = stringr::str_c(
        base::sort(
          .data[["source_scale_rule_id"]][
            .data[["review_status"]] == "approved"
          ]
        ),
        collapse = ";"
      ),
      .groups = "drop"
    )
  vec_matched_proposal_ids <-
    data_candidate_source_memberships |>
    dplyr::inner_join(
      data_source_scale_proposals,
      by = dplyr::join_by(data_source_id, trait_domain_name),
      relationship = "many-to-one"
    ) |>
    dplyr::pull("source_scale_rule_id") |>
    base::unique()
  assertthat::assert_that(
    base::all(
      data_source_scale_proposals[["review_status"]] != "proposed" |
        data_source_scale_proposals[["source_scale_rule_id"]] %in%
        vec_matched_proposal_ids
    ),
    msg = "Every proposed source rule must affect a current exception."
  )

  data_investigation_audit <-
    data_trait_review_exceptions |>
    dplyr::left_join(
      data_proposal_memberships,
      by = dplyr::join_by(candidate_id),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      n_source_rules = tidyr::replace_na(
        .data[["n_source_rules"]],
        0L
      ),
      n_proposed_source_rules = tidyr::replace_na(
        .data[["n_proposed_source_rules"]],
        0L
      ),
      n_approved_source_rules = tidyr::replace_na(
        .data[["n_approved_source_rules"]],
        0L
      ),
      proposed_source_rule_ids = tidyr::replace_na(
        .data[["proposed_source_rule_ids"]],
        ""
      ),
      approved_source_rule_ids = tidyr::replace_na(
        .data[["approved_source_rule_ids"]],
        ""
      ),
      investigation_outcome = dplyr::case_when(
        .data[["n_source_rules"]] == 0L ~
          "approve_none_grouped",
        .data[["n_proposed_source_rules"]] > 0L ~
          "pending_source_rule_approval",
        .data[["n_approved_source_rules"]] ==
          .data[["n_source_rules"]] ~
          "approve_none_after_source_rule",
        TRUE ~ "pending_source_rule_approval"
      )
    )
  data_approved_decisions <-
    data_investigation_audit |>
    dplyr::filter(
      .data[["investigation_outcome"]] !=
        "pending_source_rule_approval"
    ) |>
    dplyr::mutate(
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = NA_real_,
      value_upper_inclusive = NA,
      action = "none",
      scale_factor = NA_real_,
      rationale = dplyr::if_else(
        .data[["investigation_outcome"]] ==
          "approve_none_after_source_rule",
        stringr::str_c(
          "Approved source scaling resolves the identified unit issue; ",
          "no additional taxon-specific correction is required."
        ),
        stringr::str_c(
          "No correction is supported after grouped source investigation; ",
          "the approved conservative policy resolves this candidate to none."
        )
      ),
      decision_key = stringr::str_c(
        .data[["candidate_id"]],
        "none",
        dplyr::if_else(
          .data[["investigation_outcome"]] ==
            "approve_none_after_source_rule",
          "grouped_source_approval_v1",
          "grouped_investigation_v1"
        ),
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
        "grouped_investigation:",
        .data[["candidate_id"]]
      ),
      review_status = "approved",
      reviewer = stringr::str_trim(reviewer),
      reviewed_at = reviewed_at
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
  data_pending_candidates <-
    data_investigation_audit |>
    dplyr::filter(
      .data[["investigation_outcome"]] ==
        "pending_source_rule_approval"
    )
  data_investigation_summary <-
    data_investigation_audit |>
    dplyr::count(
      .data[["trait_domain_name"]],
      .data[["investigation_outcome"]],
      name = "n_candidates"
    ) |>
    dplyr::arrange(
      .data[["trait_domain_name"]],
      .data[["investigation_outcome"]]
    )

  assertthat::assert_that(
    base::nrow(data_investigation_audit) ==
      base::nrow(data_trait_review_exceptions),
    !base::anyDuplicated(data_approved_decisions[["decision_id"]]),
    msg = "Grouped investigation must preserve candidates and decisions."
  )
  return(
    base::list(
      data_investigation_audit = data_investigation_audit,
      data_approved_decisions = data_approved_decisions,
      data_pending_candidates = data_pending_candidates,
      data_investigation_summary = data_investigation_summary
    )
  )
}

#' @title Build Trait Review Policy Outputs
#' @description
#' Builds proposed decisions, a bounded agent-review queue, and policy summaries
#' from all-domain trait-review recommendations without approving decisions.
#' @param data_candidate_recommendations
#' Candidate recommendations returned by
#' [diagnose_trait_review_candidates()].
#' @param evidence_reference
#' Non-empty reference to the policy report supporting the proposals.
#' @param max_agent_candidates_per_domain
#' Maximum number of targeted agent-review candidates retained per domain.
#' @param agent_batch_size
#' Maximum number of candidates assigned to one agent batch.
#' @return
#' A named list containing `data_policy_proposals`,
#' `data_agent_review_queue`, and `data_policy_summary`.
#' @examples
#' recommendations <- tibble::tibble(
#'   candidate_id = digest::digest(
#'     "raw|Taxon A|Diaspore mass",
#'     algo = "sha256",
#'     serialize = FALSE
#'   ),
#'   taxon_name = "Taxon A",
#'   trait_domain_name = "Diaspore mass",
#'   n_records_current = 1L,
#'   deterministic_outcome = "retain_flagged_uncertain",
#'   suggested_action = "none",
#'   acceptance_eligibility = "eligible_policy_acceptance",
#'   recommendation_rationale = "No objective error evidence.",
#'   candidate_impact_score = 0.5
#' )
#' build_trait_review_policy_outputs(
#'   recommendations,
#'   evidence_reference = "report.html"
#' )
#' @export
build_trait_review_policy_outputs <- function(
    data_candidate_recommendations,
    evidence_reference,
    max_agent_candidates_per_domain = 25L,
    agent_batch_size = 25L) {
  vec_required_columns <-
    base::c(
      "candidate_id",
      "taxon_name",
      "trait_domain_name",
      "n_records_current",
      "deterministic_outcome",
      "suggested_action",
      "acceptance_eligibility",
      "recommendation_rationale",
      "candidate_impact_score"
    )
  assertthat::assert_that(
    base::is.data.frame(data_candidate_recommendations),
    base::all(
      vec_required_columns %in%
        base::names(data_candidate_recommendations)
    ),
    msg = "Candidate recommendations are missing required columns."
  )
  assertthat::assert_that(
    base::is.character(evidence_reference),
    base::length(evidence_reference) == 1L,
    !base::is.na(evidence_reference),
    base::nzchar(evidence_reference),
    msg = "The evidence reference must be one non-empty string."
  )
  list_integer_arguments <-
    base::list(
      max_agent_candidates_per_domain =
        max_agent_candidates_per_domain,
      agent_batch_size = agent_batch_size
    )
  flag_valid_integer_arguments <-
    purrr::map_lgl(
      list_integer_arguments,
      ~ base::is.numeric(.x) &&
        base::length(.x) == 1L &&
        base::is.finite(.x) &&
        .x >= 1L &&
        .x == base::as.integer(.x)
    )
  assertthat::assert_that(
    base::all(flag_valid_integer_arguments),
    msg = "Agent-review limits must be positive integers."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_candidate_recommendations[["candidate_id"]]
    ),
    base::all(
      stringr::str_detect(
        data_candidate_recommendations[["candidate_id"]],
        "^[0-9a-f]{64}$"
      )
    ),
    msg = "Candidate identifiers must be unique SHA-256 hashes."
  )

  data_policy_proposals <-
    data_candidate_recommendations |>
    dplyr::filter(
      .data[["acceptance_eligibility"]] ==
        "eligible_policy_acceptance",
      .data[["suggested_action"]] %in% base::c("none", "exclude")
    ) |>
    dplyr::mutate(
      decision_key = dplyr::if_else(
        .data[["suggested_action"]] == "exclude",
        stringr::str_c(
          .data[["candidate_id"]],
          "exclude",
          "value<=0",
          sep = "|"
        ),
        stringr::str_c(
          .data[["candidate_id"]],
          "none",
          "whole_group",
          sep = "|"
        )
      ),
      decision_id = base::vapply(
        .data[["decision_key"]],
        digest::digest,
        base::character(1L),
        algo = "sha256",
        serialize = FALSE
      ),
      trait_name = NA_character_,
      dataset_id = NA_real_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = dplyr::if_else(
        .data[["suggested_action"]] == "exclude",
        0,
        NA_real_
      ),
      value_upper_inclusive = dplyr::if_else(
        .data[["suggested_action"]] == "exclude",
        TRUE,
        NA
      ),
      action = .data[["suggested_action"]],
      scale_factor = NA_real_,
      rationale = .data[["recommendation_rationale"]],
      evidence_reference = evidence_reference,
      source_reference = stringr::str_c(
        "policy_candidate:",
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

  max_agent_candidates_integer <-
    base::as.integer(max_agent_candidates_per_domain)
  agent_batch_size_integer <-
    base::as.integer(agent_batch_size)
  data_agent_review_queue <-
    data_candidate_recommendations |>
    dplyr::filter(
      .data[["acceptance_eligibility"]] == "requires_agent_review"
    ) |>
    dplyr::mutate(
      agent_priority = dplyr::case_when(
        .data[["deterministic_outcome"]] %in%
          base::c(
            "validate_recovered_proposal",
            "investigate_recovered_proposal",
            "investigate_submitted_note",
            "investigate_invalid_values"
          ) ~ 1L,
        .data[["deterministic_outcome"]] ==
          "investigate_unit_pattern" ~ 2L,
        .data[["deterministic_outcome"]] ==
          "investigate_historical_drift" ~ 3L,
        TRUE ~ 4L
      )
    ) |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    dplyr::arrange(
      .data[["agent_priority"]],
      dplyr::desc(.data[["candidate_impact_score"]]),
      .data[["taxon_name"]],
      .by_group = TRUE
    ) |>
    dplyr::slice_head(n = max_agent_candidates_integer) |>
    dplyr::mutate(
      agent_review_order = dplyr::row_number(),
      batch_number = base::as.integer(
        base::ceiling(
          .data[["agent_review_order"]] / agent_batch_size_integer
        )
      ),
      domain_slug = stringr::str_replace_all(
        stringr::str_to_lower(.data[["trait_domain_name"]]),
        "[^a-z0-9]+",
        "_"
      ),
      agent_batch_id = stringr::str_c(
        .data[["domain_slug"]],
        stringr::str_pad(
          .data[["batch_number"]],
          width = 2L,
          pad = "0"
        ),
        sep = "_"
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-"domain_slug")

  data_policy_summary <-
    data_candidate_recommendations |>
    dplyr::group_by(
      .data[["trait_domain_name"]],
      .data[["deterministic_outcome"]],
      .data[["suggested_action"]],
      .data[["acceptance_eligibility"]]
    ) |>
    dplyr::summarise(
      n_candidates = dplyr::n(),
      n_records = base::sum(.data[["n_records_current"]]),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data[["trait_domain_name"]],
      .data[["deterministic_outcome"]]
    )

  res <-
    base::list(
      data_policy_proposals = data_policy_proposals,
      data_agent_review_queue = data_agent_review_queue,
      data_policy_summary = data_policy_summary
    )
  return(res)
}

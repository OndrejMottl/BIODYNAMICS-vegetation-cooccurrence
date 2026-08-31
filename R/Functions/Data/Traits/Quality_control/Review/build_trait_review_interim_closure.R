#' @title Build Interim Trait Review Closure
#' @description
#' Converts fully investigated candidates without objective correction evidence
#' into approved no-action decisions. Nonpositive invalid values become narrow
#' exclusions, while corroborated scale or source patterns remain exceptions.
#' @param data_trait_review_candidates Current trait-review candidates.
#' @param data_trait_review_decisions Existing trait-review decisions.
#' @param data_candidate_triage Programmatic candidate triage.
#' @param data_candidate_reconciliation Programmatic reconciliation results.
#' @param reviewer Name of the approving human reviewer.
#' @param reviewed_at ISO review date.
#' @param evidence_reference Path to the durable closure report.
#' @return
#' A named list containing the closure audit, new approved decisions,
#' unresolved exceptions, and a closure summary.
#' @export
build_trait_review_interim_closure <- function(
    data_trait_review_candidates,
    data_trait_review_decisions,
    data_candidate_triage,
    data_candidate_reconciliation,
    reviewer,
    reviewed_at,
    evidence_reference) {
  list_inputs <-
    base::list(
      candidates = data_trait_review_candidates,
      decisions = data_trait_review_decisions,
      triage = data_candidate_triage,
      reconciliation = data_candidate_reconciliation
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All interim-closure inputs must be data frames."
  )
  list_required_columns <-
    base::list(
      candidates = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "n_invalid_values"
      ),
      decisions = base::c("candidate_id", "review_status"),
      triage = base::c("candidate_id", "triage_outcome"),
      reconciliation = base::c(
        "candidate_id",
        "reconciliation_outcome"
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
    msg = "Interim-closure inputs are missing required columns."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_trait_review_candidates[["candidate_id"]]
    ),
    !base::anyDuplicated(data_candidate_triage[["candidate_id"]]),
    !base::anyDuplicated(
      data_candidate_reconciliation[["candidate_id"]]
    ),
    msg = "Closure candidates, triage, and reconciliation must be unique."
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

  vec_covered_candidate_ids <-
    data_trait_review_decisions |>
    dplyr::filter(.data[["review_status"]] == "approved") |>
    dplyr::pull("candidate_id") |>
    base::unique()
  data_uncovered_candidates <-
    data_trait_review_candidates |>
    dplyr::filter(
      !.data[["candidate_id"]] %in% vec_covered_candidate_ids
    )
  vec_missing_triage_ids <-
    base::setdiff(
      data_uncovered_candidates[["candidate_id"]],
      data_candidate_triage[["candidate_id"]]
    )
  assertthat::assert_that(
    base::length(vec_missing_triage_ids) == 0L,
    msg = paste0(
      "Programmatic triage must cover every uncovered candidate."
    )
  )

  vec_objective_triage_outcomes <-
    base::c("agent_repeated_source_pattern")
  vec_objective_reconciliation_outcomes <-
    base::c(
      "propose_scale_validated_threshold",
      "propose_scale_corroborated_source",
      "agent_strong_isolated_source_pattern"
    )
  data_closure_audit <-
    data_uncovered_candidates |>
    dplyr::left_join(
      data_candidate_triage |>
        dplyr::select("candidate_id", "triage_outcome"),
      by = dplyr::join_by(candidate_id),
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      data_candidate_reconciliation |>
        dplyr::select("candidate_id", "reconciliation_outcome"),
      by = dplyr::join_by(candidate_id),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      has_objective_scale_evidence =
        .data[["triage_outcome"]] %in%
          vec_objective_triage_outcomes |
        .data[["reconciliation_outcome"]] %in%
          vec_objective_reconciliation_outcomes,
      closure_outcome = dplyr::case_when(
        .data[["has_objective_scale_evidence"]] ~
          "pending_objective_scale_evidence",
        .data[["n_invalid_values"]] > 0L ~
          "approve_exclude_invalid_nonpositive",
        TRUE ~ "approve_none_insufficient_evidence"
      )
    )

  data_approved_decisions <-
    data_closure_audit |>
    dplyr::filter(
      .data[["closure_outcome"]] !=
        "pending_objective_scale_evidence"
    ) |>
    dplyr::mutate(
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = dplyr::if_else(
        .data[["closure_outcome"]] ==
          "approve_exclude_invalid_nonpositive",
        0,
        NA_real_
      ),
      value_upper_inclusive = dplyr::if_else(
        .data[["closure_outcome"]] ==
          "approve_exclude_invalid_nonpositive",
        TRUE,
        NA
      ),
      action = dplyr::if_else(
        .data[["closure_outcome"]] ==
          "approve_exclude_invalid_nonpositive",
        "exclude",
        "none"
      ),
      scale_factor = NA_real_,
      rationale = dplyr::if_else(
        .data[["action"]] == "exclude",
        paste0(
          "Exclude nonpositive values because the positive-valued trait ",
          "domain cannot contain negative or zero measurements."
        ),
        paste0(
          "No correction is supported after structured investigation; ",
          "the approved conservative policy resolves this candidate to none."
        )
      ),
      decision_key = stringr::str_c(
        .data[["candidate_id"]],
        .data[["action"]],
        tidyr::replace_na(
          base::as.character(.data[["value_upper"]]),
          ""
        ),
        "interim_closure_v1",
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
        "interim_closure:",
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
  data_exceptions <-
    data_closure_audit |>
    dplyr::filter(
      .data[["closure_outcome"]] ==
        "pending_objective_scale_evidence"
    )
  data_closure_summary <-
    data_closure_audit |>
    dplyr::count(
      .data[["trait_domain_name"]],
      .data[["closure_outcome"]],
      name = "n_candidates"
    ) |>
    dplyr::arrange(
      .data[["trait_domain_name"]],
      .data[["closure_outcome"]]
    )

  assertthat::assert_that(
    base::nrow(data_closure_audit) ==
      base::nrow(data_uncovered_candidates),
    !base::anyDuplicated(data_approved_decisions[["decision_id"]]),
    msg = "Interim closure must preserve candidates and unique decisions."
  )
  return(
    base::list(
      data_closure_audit = data_closure_audit,
      data_approved_decisions = data_approved_decisions,
      data_exceptions = data_exceptions,
      data_closure_summary = data_closure_summary
    )
  )
}

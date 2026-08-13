#' @title Validate Trait Review Decisions
#' @description
#' Validates review schema, human approval, candidate coverage, selectors,
#' and correction-rule conflicts against current trait records.
#' @param data_trait_review_decisions
#' Decision data loaded by [load_trait_review_decisions()].
#' @param data_trait_records
#' Current trait records for the review stage.
#' @param data_trait_review_candidates
#' Current candidates from [build_trait_review_candidates()].
#' @return
#' A tibble containing validated review decisions.
#' @export
validate_trait_review_decisions <- function(
    data_trait_review_decisions,
    data_trait_records,
    data_trait_review_candidates) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_review_decisions),
    base::is.data.frame(data_trait_records),
    base::is.data.frame(data_trait_review_candidates),
    msg = "Decisions, records, and candidates must be data frames."
  )
  if (
    base::nrow(data_trait_review_candidates) > 0L &&
      base::nrow(data_trait_review_decisions) == 0L
  ) {
    cli::cli_abort(
      "Approved decision coverage is incomplete for current candidates."
    )
  }

  decision_columns <-
    base::c(
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
  record_columns <-
    base::c("taxon_name", "trait_domain_name", "trait_value")
  candidate_columns <-
    base::c("candidate_id", "taxon_name", "trait_domain_name")
  assertthat::assert_that(
    base::all(
      decision_columns %in% base::names(data_trait_review_decisions)
    ),
    base::all(record_columns %in% base::names(data_trait_records)),
    base::all(
      candidate_columns %in% base::names(data_trait_review_candidates)
    ),
    msg = "Trait review inputs are missing required columns."
  )

  character_columns <-
    base::c(
      "decision_id",
      "candidate_id",
      "taxon_name",
      "trait_domain_name",
      "trait_name",
      "action",
      "rationale",
      "evidence_reference",
      "source_reference",
      "review_status",
      "reviewer",
      "reviewed_at"
    )
  has_edge_whitespace <-
    base::vapply(
      data_trait_review_decisions[character_columns],
      function(column_value) {
        base::any(
          !base::is.na(column_value) &
            column_value != stringr::str_trim(column_value),
          na.rm = TRUE
        )
      },
      logical(1L)
    )
  if (base::any(has_edge_whitespace)) {
    cli::cli_abort("Trait review decisions contain edge whitespace.")
  }

  valid_hash <- "^[0-9a-f]{64}$"
  if (
    base::any(
      !stringr::str_detect(
        data_trait_review_decisions[["decision_id"]],
        valid_hash
      )
    ) ||
      base::anyDuplicated(
        data_trait_review_decisions[["decision_id"]]
      ) > 0L
  ) {
    cli::cli_abort("Decision identifiers must be unique SHA-256 hashes.")
  }
  if (
    base::any(
      !stringr::str_detect(
        data_trait_review_decisions[["candidate_id"]],
        valid_hash
      )
    )
  ) {
    cli::cli_abort("Candidate identifiers must be SHA-256 hashes.")
  }

  allowed_actions <- base::c("none", "exclude", "scale")
  allowed_statuses <- base::c("proposed", "approved", "rejected")
  if (
    base::any(
      !data_trait_review_decisions[["action"]] %in% allowed_actions
    )
  ) {
    cli::cli_abort("Actions must be 'none', 'exclude', or 'scale'.")
  }
  if (
    base::any(
      !data_trait_review_decisions[["review_status"]] %in%
        allowed_statuses
    )
  ) {
    cli::cli_abort("Review status is invalid.")
  }

  required_text_columns <-
    base::c(
      "taxon_name",
      "trait_domain_name",
      "rationale",
      "evidence_reference",
      "source_reference"
    )
  missing_required_text <-
    base::vapply(
      data_trait_review_decisions[required_text_columns],
      function(column_value) {
        base::any(base::is.na(column_value) | column_value == "")
      },
      logical(1L)
    )
  if (base::any(missing_required_text)) {
    cli::cli_abort("Required decision text fields cannot be blank.")
  }

  candidate_index <-
    base::match(
      data_trait_review_decisions[["candidate_id"]],
      data_trait_review_candidates[["candidate_id"]]
    )
  if (base::any(base::is.na(candidate_index))) {
    cli::cli_abort("Every decision must match a current candidate.")
  }
  matching_candidate_taxa <-
    data_trait_review_candidates[["taxon_name"]][candidate_index]
  matching_candidate_domains <-
    data_trait_review_candidates[["trait_domain_name"]][candidate_index]
  if (
    base::any(
      data_trait_review_decisions[["taxon_name"]] !=
        matching_candidate_taxa |
        data_trait_review_decisions[["trait_domain_name"]] !=
          matching_candidate_domains
    )
  ) {
    cli::cli_abort("Decision keys do not match their candidates.")
  }

  is_approved <-
    data_trait_review_decisions[["review_status"]] == "approved"
  candidate_coverage <-
    data_trait_review_candidates[["candidate_id"]] %in%
      data_trait_review_decisions[["candidate_id"]][is_approved]
  if (!base::all(candidate_coverage)) {
    cli::cli_abort(
      "Approved decision coverage is incomplete for current candidates."
    )
  }

  needs_human_metadata <-
    data_trait_review_decisions[["review_status"]] %in%
      base::c("approved", "rejected")
  reviewer <- data_trait_review_decisions[["reviewer"]]
  reviewed_at <- data_trait_review_decisions[["reviewed_at"]]
  invalid_reviewer <-
    needs_human_metadata & (base::is.na(reviewer) | reviewer == "")
  invalid_date_text <-
    needs_human_metadata &
    (
      base::is.na(reviewed_at) |
        !stringr::str_detect(reviewed_at, "^\\d{4}-\\d{2}-\\d{2}$")
    )
  invalid_date_value <-
    needs_human_metadata &
    base::is.na(base::suppressWarnings(base::as.Date(reviewed_at)))
  if (
    base::any(invalid_reviewer) ||
      base::any(invalid_date_text) ||
      base::any(invalid_date_value)
  ) {
    cli::cli_abort(
      "Human-reviewed decisions require reviewer and valid review date."
    )
  }

  is_scale <- data_trait_review_decisions[["action"]] == "scale"
  scale_factor <- data_trait_review_decisions[["scale_factor"]]
  if (
    base::any(
      is_scale &
        (
          base::is.na(scale_factor) |
            !base::is.finite(scale_factor) |
            scale_factor <= 0
        )
    ) ||
      base::any(!is_scale & !base::is.na(scale_factor))
  ) {
    cli::cli_abort(
      "Scale actions require one positive factor; other actions require none."
    )
  }

  value_lower <- data_trait_review_decisions[["value_lower"]]
  lower_inclusive <-
    data_trait_review_decisions[["value_lower_inclusive"]]
  value_upper <- data_trait_review_decisions[["value_upper"]]
  upper_inclusive <-
    data_trait_review_decisions[["value_upper_inclusive"]]
  if (
    base::any(base::is.na(value_lower) != base::is.na(lower_inclusive)) ||
      base::any(
        base::is.na(value_upper) != base::is.na(upper_inclusive)
      )
  ) {
    cli::cli_abort("Value bounds and inclusivity flags must be paired.")
  }
  has_both_bounds <-
    !base::is.na(value_lower) & !base::is.na(value_upper)
  invalid_bound_order <-
    has_both_bounds & value_lower > value_upper
  empty_equal_bounds <-
    has_both_bounds &
    value_lower == value_upper &
    (!lower_inclusive | !upper_inclusive)
  if (
    base::any(invalid_bound_order) ||
      base::any(empty_equal_bounds)
  ) {
    cli::cli_abort("Decision value bounds are invalid.")
  }

  has_trait_selector <-
    !base::is.na(data_trait_review_decisions[["trait_name"]]) &
    data_trait_review_decisions[["trait_name"]] != ""
  has_dataset_selector <-
    !base::is.na(data_trait_review_decisions[["dataset_id"]])
  is_none <- data_trait_review_decisions[["action"]] == "none"
  has_any_selector <-
    has_trait_selector |
    has_dataset_selector |
    !base::is.na(value_lower) |
    !base::is.na(value_upper)
  if (base::any(is_none & has_any_selector)) {
    cli::cli_abort("No-action decisions cannot contain selectors.")
  }
  if (
    base::any(has_trait_selector) &&
      !"trait_name" %in% base::names(data_trait_records)
  ) {
    cli::cli_abort("A trait-name selector cannot match current records.")
  }
  if (
    base::any(has_dataset_selector) &&
      !"dataset_id" %in% base::names(data_trait_records)
  ) {
    cli::cli_abort("A dataset selector cannot match current records.")
  }

  approved_actions <-
    data_trait_review_decisions[is_approved, , drop = FALSE]
  conflicting_candidates <-
    approved_actions |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      has_none = base::any(.data[["action"]] == "none"),
      has_correction = base::any(.data[["action"]] != "none"),
      .groups = "drop"
    ) |>
    dplyr::filter(.data[["has_none"]] & .data[["has_correction"]])
  if (base::nrow(conflicting_candidates) > 0L) {
    cli::cli_abort(
      "Approved no-action and correction decisions conflict."
    )
  }

  correction_rules <-
    data_trait_review_decisions |>
    dplyr::filter(.data[["action"]] != "none")
  matched_record_ids <-
    base::vector("list", base::nrow(correction_rules))
  for (rule_index in base::seq_len(base::nrow(correction_rules))) {
    rule <- correction_rules[rule_index, , drop = FALSE]
    is_match <-
      data_trait_records[["taxon_name"]] == rule[["taxon_name"]][[1L]] &
      data_trait_records[["trait_domain_name"]] ==
        rule[["trait_domain_name"]][[1L]]
    trait_name <- rule[["trait_name"]][[1L]]
    if (!base::is.na(trait_name) && trait_name != "") {
      is_match <-
        is_match & data_trait_records[["trait_name"]] == trait_name
    }
    dataset_id <- rule[["dataset_id"]][[1L]]
    if (!base::is.na(dataset_id)) {
      is_match <-
        is_match & data_trait_records[["dataset_id"]] == dataset_id
    }
    lower <- rule[["value_lower"]][[1L]]
    if (!base::is.na(lower)) {
      if (base::isTRUE(rule[["value_lower_inclusive"]][[1L]])) {
        is_match <-
          is_match & data_trait_records[["trait_value"]] >= lower
      } else {
        is_match <-
          is_match & data_trait_records[["trait_value"]] > lower
      }
    }
    upper <- rule[["value_upper"]][[1L]]
    if (!base::is.na(upper)) {
      if (base::isTRUE(rule[["value_upper_inclusive"]][[1L]])) {
        is_match <-
          is_match & data_trait_records[["trait_value"]] <= upper
      } else {
        is_match <-
          is_match & data_trait_records[["trait_value"]] < upper
      }
    }
    is_match[base::is.na(is_match)] <- FALSE
    matched_record_ids[[rule_index]] <- base::which(is_match)
  }

  if (
    base::any(
      base::lengths(matched_record_ids) == 0L
    )
  ) {
    cli::cli_abort(
      "Every approved correction selector must match current records."
    )
  }
  is_approved_correction <-
    correction_rules[["review_status"]] == "approved"
  all_matched_record_ids <-
    base::unlist(matched_record_ids[is_approved_correction])
  if (base::anyDuplicated(all_matched_record_ids) > 0L) {
    cli::cli_abort("Approved correction selectors overlap.")
  }

  return(data_trait_review_decisions)
}

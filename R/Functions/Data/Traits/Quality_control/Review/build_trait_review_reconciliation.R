#' @title Build Trait Review Reconciliation
#' @description
#' Combines the mandatory trait-review queue with historical report coverage,
#' submitted review rows, and recovered decision proposals. The result has one
#' row per current candidate and assigns an auditable remaining-work category.
#' @param data_trait_review_candidates
#' Current candidate table from [build_trait_review_candidates()].
#' @param data_historical_review_scope
#' Historical report index with `candidate_id`, `historical_report_path`,
#' `historical_report_page`, `historical_reviewed`, and the coverage basis.
#' @param data_review_submission_audit
#' Derived submission audit with `candidate_id`, `source_row`, and
#' `proposal_type`.
#' @param data_review_decision_proposals
#' Recovered proposal table with `candidate_id` and `decision_id`.
#' @return
#' A tibble containing every current candidate exactly once, historical and
#' submission counts, proposal status, implicit no-action eligibility, and
#' `remaining_review_category`.
#' @examples
#' candidates <- tibble::tibble(
#'   candidate_id = "candidate-a",
#'   review_stage = "raw",
#'   taxon_name = "Taxon A",
#'   trait_domain_name = "Plant heigh",
#'   n_records = 10L,
#'   n_trait_names = 1L,
#'   n_datasets = 1L,
#'   n_domain_outliers = 0L,
#'   n_taxon_outliers = 1L,
#'   source_references = "",
#'   candidate_reasons = "taxon_outlier"
#' )
#' historical <- tibble::tibble(
#'   candidate_id = "candidate-a",
#'   historical_report_path = "report.pdf",
#'   historical_report_page = 2L,
#'   historical_reviewed = TRUE,
#'   historical_review_basis = "complete domain review"
#' )
#' audit <- tibble::tibble(
#'   candidate_id = character(),
#'   source_row = integer(),
#'   proposal_type = character()
#' )
#' proposals <- tibble::tibble(
#'   candidate_id = character(),
#'   decision_id = character()
#' )
#' build_trait_review_reconciliation(
#'   candidates,
#'   historical,
#'   audit,
#'   proposals
#' )
#' @export
build_trait_review_reconciliation <- function(
    data_trait_review_candidates,
    data_historical_review_scope,
    data_review_submission_audit,
    data_review_decision_proposals) {
  list_inputs <-
    base::list(
      candidates = data_trait_review_candidates,
      historical_scope = data_historical_review_scope,
      submission_audit = data_review_submission_audit,
      proposals = data_review_decision_proposals
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All reconciliation inputs must be data frames."
  )

  list_required_columns <-
    base::list(
      candidates = base::c(
        "candidate_id",
        "review_stage",
        "taxon_name",
        "trait_domain_name"
      ),
      historical_scope = base::c(
        "candidate_id",
        "historical_report_path",
        "historical_report_page",
        "historical_reviewed",
        "historical_review_basis"
      ),
      submission_audit = base::c(
        "candidate_id",
        "source_row",
        "proposal_type"
      ),
      proposals = base::c("candidate_id", "decision_id")
    )
  vec_missing_columns <-
    purrr::imap_chr(
      list_required_columns,
      function(vec_required, input_name) {
        vec_missing <-
          base::setdiff(
            vec_required,
            base::names(list_inputs[[input_name]])
          )
        stringr::str_c(vec_missing, collapse = ",")
      }
    )
  assertthat::assert_that(
    base::all(vec_missing_columns == ""),
    msg = "Reconciliation inputs are missing required columns."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_trait_review_candidates[["candidate_id"]]
    ),
    msg = "Current candidate_id values must be unique."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_historical_review_scope[["candidate_id"]]
    ),
    msg = "Historical candidate_id values must be unique."
  )

  data_submission_summary <-
    data_review_submission_audit |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_submission_rows = dplyr::n(),
      submission_rows = stringr::str_c(
        base::sort(base::unique(.data[["source_row"]])),
        collapse = ";"
      ),
      n_pending_submission_rows = base::sum(
        .data[["proposal_type"]] == "pending_visual_review"
      ),
      .groups = "drop"
    )

  data_proposal_summary <-
    data_review_decision_proposals |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_recovered_proposals = dplyr::n_distinct(
        .data[["decision_id"]]
      ),
      .groups = "drop"
    )

  data_reconciliation <-
    data_trait_review_candidates |>
    dplyr::left_join(
      data_historical_review_scope |>
        dplyr::select(
          dplyr::all_of(
            list_required_columns[["historical_scope"]]
          )
        ),
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_submission_summary,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_proposal_summary,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::mutate(
      historical_scope_status = dplyr::case_when(
        .data[["historical_reviewed"]] %in% TRUE ~
          "confirmed_previous_review",
        .data[["historical_reviewed"]] %in% FALSE ~
          "unfinished_previous_review",
        TRUE ~ "not_in_previous_report"
      ),
      dplyr::across(
        dplyr::all_of(
          base::c(
            "n_submission_rows",
            "n_pending_submission_rows",
            "n_recovered_proposals"
          )
        ),
        ~ base::as.integer(tidyr::replace_na(.x, 0L))
      ),
      submission_rows = tidyr::replace_na(
        .data[["submission_rows"]],
        ""
      ),
      recovered_proposal_status = dplyr::case_when(
        .data[["n_pending_submission_rows"]] > 0L &
          .data[["n_recovered_proposals"]] > 0L ~
          "mixed_proposal_and_pending",
        .data[["n_pending_submission_rows"]] > 0L ~
          "pending_interpretation",
        .data[["n_recovered_proposals"]] > 0L ~
          "proposal_available",
        .data[["n_submission_rows"]] > 0L ~
          "submission_without_proposal",
        TRUE ~ "no_submitted_correction"
      ),
      implicit_none_proposal_eligible =
        .data[["historical_scope_status"]] ==
          "confirmed_previous_review" &
        .data[["n_submission_rows"]] == 0L,
      remaining_review_category = dplyr::case_when(
        .data[["n_pending_submission_rows"]] > 0L ~
          "submitted_correction_needs_interpretation",
        .data[["n_recovered_proposals"]] > 0L ~
          "recovered_correction_needs_validation",
        .data[["n_submission_rows"]] > 0L ~
          "submitted_correction_needs_interpretation",
        .data[["implicit_none_proposal_eligible"]] ~
          "prior_no_action_needs_revalidation",
        .data[["historical_scope_status"]] ==
          "unfinished_previous_review" ~
          "unfinished_historical_review",
        TRUE ~ "new_or_changed_candidate"
      )
    ) |>
    dplyr::select(
      dplyr::all_of(base::names(data_trait_review_candidates)),
      "historical_scope_status",
      "historical_report_path",
      "historical_report_page",
      "historical_review_basis",
      "n_submission_rows",
      "submission_rows",
      "n_recovered_proposals",
      "n_pending_submission_rows",
      "recovered_proposal_status",
      "implicit_none_proposal_eligible",
      "remaining_review_category"
    )

  assertthat::assert_that(
    base::nrow(data_reconciliation) ==
      base::nrow(data_trait_review_candidates),
    msg = "Reconciliation must preserve exactly one row per candidate."
  )

  return(data_reconciliation)
}

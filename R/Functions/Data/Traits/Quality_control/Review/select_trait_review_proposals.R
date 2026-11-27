#' @title Select Trait Review Proposals
#' @description
#' Selects one proposal for every trait-review candidate from the automated
#' sources, in a fixed order of precedence: the conservative policy, then
#' the interim closure, then the human review queue.
#' @param data_trait_review_candidates
#' Current review candidates with unique `candidate_id`, `taxon_name`, and
#' `trait_domain_name`.
#' @param data_policy_proposals
#' Policy proposals in the canonical decision columns, at most one row per
#' candidate (from [build_trait_review_policy_outputs()]).
#' @param data_closure_decisions
#' Closure decisions in the canonical decision columns, at most one row per
#' candidate (from [build_trait_review_interim_closure()]).
#' @param data_queue_suggestions
#' Suggested decisions in the canonical decision columns for candidates that
#' need human review, for example scale proposals of
#' [build_trait_review_programmatic_reconciliation()]. A candidate may have
#' several rows.
#' @return
#' A tibble in the canonical decision columns plus `proposal_source`
#' (`"policy"`, `"closure"`, or `"queue"`) and `has_overridden_suggestion`.
#' Every row has `review_status` `"proposed"` and no reviewer or review
#' date. Queue candidates keep all their suggestion rows; a queue candidate
#' without a suggestion gets one row with no `decision_id` and no `action`,
#' to be completed by the reviewer. Rows follow the candidate order.
#' @details
#' A candidate with a policy proposal takes it, and its closure decision and
#' suggestions are not used. A candidate without one takes its closure
#' decision. All other candidates form the queue. Nothing is approved here:
#' `has_overridden_suggestion` marks policy and closure proposals of
#' candidates that also have a queue suggestion, so the reviewer can see
#' which suggestions were set aside.
#' @seealso [build_trait_review_policy_outputs()],
#'   [build_trait_review_interim_closure()],
#'   [validate_trait_review_decisions()]
#' @export
select_trait_review_proposals <- function(
    data_trait_review_candidates,
    data_policy_proposals,
    data_closure_decisions,
    data_queue_suggestions) {
  vec_decision_columns <-
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
  list_proposal_inputs <-
    base::list(
      data_policy_proposals,
      data_closure_decisions,
      data_queue_suggestions
    )

  assertthat::assert_that(
    base::is.data.frame(data_trait_review_candidates),
    base::all(purrr::map_lgl(list_proposal_inputs, base::is.data.frame)),
    msg = "Candidates and proposal inputs must be data frames."
  )
  assertthat::assert_that(
    base::all(
      base::c("candidate_id", "taxon_name", "trait_domain_name") %in%
        base::names(data_trait_review_candidates)
    ),
    !base::anyDuplicated(data_trait_review_candidates[["candidate_id"]]),
    msg = stringr::str_c(
      "Candidates need unique candidate_id values, taxon_name, and ",
      "trait_domain_name."
    )
  )
  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        list_proposal_inputs,
        ~ base::all(vec_decision_columns %in% base::names(.x))
      )
    ),
    msg = "Proposal inputs must hold the canonical decision columns."
  )
  assertthat::assert_that(
    !base::anyDuplicated(data_policy_proposals[["candidate_id"]]),
    !base::anyDuplicated(data_closure_decisions[["candidate_id"]]),
    msg = "Policy and closure inputs need one row per candidate."
  )

  vec_candidate_ids <- data_trait_review_candidates[["candidate_id"]]
  vec_unknown_ids <-
    list_proposal_inputs |>
    purrr::map(~ .x[["candidate_id"]]) |>
    base::unlist() |>
    base::setdiff(vec_candidate_ids)

  if (
    base::length(vec_unknown_ids) > 0L
  ) {
    cli::cli_abort(
      c(
        "Proposals name unknown candidates.",
        "x" = "{base::length(vec_unknown_ids)} candidate id{?s} not found."
      )
    )
  }

  # Precedence: policy, then closure, then the human queue
  vec_policy_ids <- data_policy_proposals[["candidate_id"]]

  data_closure_selected <-
    data_closure_decisions |>
    dplyr::filter(!.data[["candidate_id"]] %in% vec_policy_ids)

  vec_queue_ids <-
    base::setdiff(
      vec_candidate_ids,
      base::c(vec_policy_ids, data_closure_selected[["candidate_id"]])
    )

  data_queue_suggested <-
    data_queue_suggestions |>
    dplyr::filter(.data[["candidate_id"]] %in% vec_queue_ids)

  data_queue_open <-
    data_trait_review_candidates |>
    dplyr::filter(
      .data[["candidate_id"]] %in% vec_queue_ids,
      !.data[["candidate_id"]] %in% data_queue_suggested[["candidate_id"]]
    ) |>
    dplyr::select("candidate_id", "taxon_name", "trait_domain_name")

  data_proposals <-
    dplyr::bind_rows(
      data_policy_proposals |>
        dplyr::select(dplyr::all_of(vec_decision_columns)) |>
        dplyr::mutate(proposal_source = "policy"),
      data_closure_selected |>
        dplyr::select(dplyr::all_of(vec_decision_columns)) |>
        dplyr::mutate(proposal_source = "closure"),
      data_queue_suggested |>
        dplyr::select(dplyr::all_of(vec_decision_columns)) |>
        dplyr::mutate(proposal_source = "queue"),
      data_queue_open |>
        dplyr::mutate(proposal_source = "queue")
    ) |>
    dplyr::select(
      dplyr::all_of(vec_decision_columns),
      "proposal_source"
    ) |>
    dplyr::mutate(
      review_status = "proposed",
      reviewer = NA_character_,
      reviewed_at = NA_character_,
      has_overridden_suggestion =
        .data[["proposal_source"]] != "queue" &
          .data[["candidate_id"]] %in%
            data_queue_suggestions[["candidate_id"]],
      candidate_order = base::match(
        .data[["candidate_id"]],
        vec_candidate_ids
      )
    ) |>
    dplyr::arrange(.data[["candidate_order"]]) |>
    dplyr::select(-"candidate_order")

  assertthat::assert_that(
    base::setequal(data_proposals[["candidate_id"]], vec_candidate_ids),
    msg = "Every candidate must receive a proposal."
  )

  return(data_proposals)
}

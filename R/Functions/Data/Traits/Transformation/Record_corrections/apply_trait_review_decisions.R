#' @title Apply Trait Review Decisions
#' @description
#' Applies approved, non-overlapping trait exclusion and scaling rules.
#' @param data_trait_records
#' Current trait records for one review stage.
#' @param data_trait_review_decisions
#' Validated decisions from [validate_trait_review_decisions()].
#' @return
#' A named list containing `data_trait_records_corrected` and
#' `data_correction_audit`.
#' @export
apply_trait_review_decisions <- function(
    data_trait_records,
    data_trait_review_decisions) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    base::is.data.frame(data_trait_review_decisions),
    msg = "Trait records and decisions must be data frames."
  )
  required_record_columns <-
    base::c("taxon_name", "trait_domain_name", "trait_value")
  required_decision_columns <-
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
      "review_status"
    )
  assertthat::assert_that(
    base::all(required_record_columns %in% base::names(data_trait_records)),
    base::all(
      required_decision_columns %in% base::names(data_trait_review_decisions)
    ),
    msg = "Trait records or decisions are missing required columns."
  )

  data_approved_decisions <-
    data_trait_review_decisions |>
    dplyr::filter(.data[["review_status"]] == "approved")
  data_corrected <-
    data_trait_records |>
    dplyr::mutate(.trait_review_row_id = dplyr::row_number())
  audit_rows <-
    base::vector("list", base::nrow(data_approved_decisions))
  excluded_row_ids <- integer()

  for (decision_index in base::seq_len(base::nrow(data_approved_decisions))) {
    decision <- data_approved_decisions[decision_index, , drop = FALSE]
    action <- decision[["action"]][[1L]]
    matching_records <-
      data_corrected[["taxon_name"]] == decision[["taxon_name"]][[1L]] &
      data_corrected[["trait_domain_name"]] ==
        decision[["trait_domain_name"]][[1L]]

    trait_name <- decision[["trait_name"]][[1L]]
    if (!base::is.na(trait_name) && trait_name != "") {
      matching_records <-
        matching_records &
        data_corrected[["trait_name"]] == trait_name
    }
    dataset_id <- decision[["dataset_id"]][[1L]]
    if (!base::is.na(dataset_id)) {
      matching_records <-
        matching_records &
        data_corrected[["dataset_id"]] == dataset_id
    }
    value_lower <- decision[["value_lower"]][[1L]]
    if (!base::is.na(value_lower)) {
      if (base::isTRUE(decision[["value_lower_inclusive"]][[1L]])) {
        matching_records <-
          matching_records &
          data_corrected[["trait_value"]] >= value_lower
      } else {
        matching_records <-
          matching_records &
          data_corrected[["trait_value"]] > value_lower
      }
    }
    value_upper <- decision[["value_upper"]][[1L]]
    if (!base::is.na(value_upper)) {
      if (base::isTRUE(decision[["value_upper_inclusive"]][[1L]])) {
        matching_records <-
          matching_records &
          data_corrected[["trait_value"]] <= value_upper
      } else {
        matching_records <-
          matching_records &
          data_corrected[["trait_value"]] < value_upper
      }
    }
    matching_records[base::is.na(matching_records)] <- FALSE

    matched_row_ids <-
      data_corrected[[".trait_review_row_id"]][matching_records]
    if (action == "none") {
      matched_row_ids <- integer()
    }
    n_matched <- base::length(matched_row_ids)
    n_excluded <- 0L
    n_scaled <- 0L
    if (action == "exclude") {
      excluded_row_ids <- base::c(excluded_row_ids, matched_row_ids)
      n_excluded <- base::as.integer(n_matched)
    } else if (action == "scale") {
      data_corrected[["trait_value"]][matching_records] <-
        data_corrected[["trait_value"]][matching_records] *
        decision[["scale_factor"]][[1L]]
      n_scaled <- base::as.integer(n_matched)
    }

    audit_rows[[decision_index]] <-
      tibble::tibble(
        decision_id = decision[["decision_id"]][[1L]],
        candidate_id = decision[["candidate_id"]][[1L]],
        action = action,
        n_matched = base::as.integer(n_matched),
        n_excluded = n_excluded,
        n_scaled = n_scaled
      )
  }

  data_corrected <-
    data_corrected |>
    dplyr::filter(
      !.data[[".trait_review_row_id"]] %in% excluded_row_ids
    ) |>
    dplyr::select(-".trait_review_row_id")

  data_correction_audit <-
    dplyr::bind_rows(audit_rows)
  if (base::nrow(data_correction_audit) == 0L) {
    data_correction_audit <-
      tibble::tibble(
        decision_id = character(),
        candidate_id = character(),
        action = character(),
        n_matched = integer(),
        n_excluded = integer(),
        n_scaled = integer()
      )
  }

  return(
    base::list(
      data_trait_records_corrected = data_corrected,
      data_correction_audit = data_correction_audit
    )
  )
}

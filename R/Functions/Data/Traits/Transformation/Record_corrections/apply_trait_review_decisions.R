#' @title Apply Trait Review Decisions
#' @description
#' Applies approved, non-overlapping trait exclusion and scaling rules.
#' @param data_trait_records
#' Current trait records for one review stage.
#' @param data_trait_review_decisions
#' Validated decisions from [validate_trait_review_decisions()].
#' @param data_trait_source_scale_record_audit
#' Optional record-level audit from [apply_trait_source_scale_rules()].
#' @return
#' A named list containing `data_trait_records_corrected` and
#' `data_correction_audit`.
#' @export
apply_trait_review_decisions <- function(
    data_trait_records,
    data_trait_review_decisions,
    data_trait_source_scale_record_audit = NULL) {
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
  record_id_columns <-
    base::c("dataset_id", "sample_id", "trait_id", "taxon_id")
  flag_use_source_audit <-
    !base::is.null(data_trait_source_scale_record_audit) &&
    base::nrow(data_trait_source_scale_record_audit) > 0L
  if (
    flag_use_source_audit
  ) {
    source_audit_columns <-
      base::c(
        record_id_columns,
        "taxon_name",
        "trait_domain_name",
        "trait_name",
        "trait_value_before",
        "scale_factor"
      )
    assertthat::assert_that(
      base::all(record_id_columns %in% base::names(data_corrected)),
      base::all(
        source_audit_columns %in%
          base::names(data_trait_source_scale_record_audit)
      ),
      msg = "Source-scale audit is missing required record provenance."
    )
    vec_current_record_keys <-
      stringr::str_c(
        data_corrected[["dataset_id"]],
        data_corrected[["sample_id"]],
        data_corrected[["trait_id"]],
        data_corrected[["taxon_id"]],
        sep = "|"
      )
    vec_source_record_keys <-
      stringr::str_c(
        data_trait_source_scale_record_audit[["dataset_id"]],
        data_trait_source_scale_record_audit[["sample_id"]],
        data_trait_source_scale_record_audit[["trait_id"]],
        data_trait_source_scale_record_audit[["taxon_id"]],
        sep = "|"
      )
    source_is_current <-
      vec_source_record_keys %in% vec_current_record_keys
    data_source_audit_current <-
      data_trait_source_scale_record_audit[
        source_is_current,
        ,
        drop = FALSE
      ]
    vec_source_record_keys_current <-
      vec_source_record_keys[source_is_current]
    current_index <-
      base::match(
        vec_source_record_keys_current,
        vec_current_record_keys
      )
    data_source_audit_current[["taxon_name"]] <-
      data_corrected[["taxon_name"]][current_index]
    data_source_audit_current[["trait_domain_name"]] <-
      data_corrected[["trait_domain_name"]][current_index]
    if (
      "trait_name" %in% base::names(data_corrected)
    ) {
      data_source_audit_current[["trait_name"]] <-
        data_corrected[["trait_name"]][current_index]
    }
  } else {
    vec_current_record_keys <- character()
    data_source_audit_current <- tibble::tibble()
    vec_source_record_keys_current <- character()
  }
  audit_rows <-
    base::vector("list", base::nrow(data_approved_decisions))
  excluded_row_ids <- integer()

  for (decision_index in base::seq_len(base::nrow(data_approved_decisions))) {
    decision <- data_approved_decisions[decision_index, , drop = FALSE]
    action <- decision[["action"]][[1L]]
    if (
      action == "none"
    ) {
      audit_rows[[decision_index]] <-
        tibble::tibble(
          decision_id = decision[["decision_id"]][[1L]],
          candidate_id = decision[["candidate_id"]][[1L]],
          action = action,
          n_matched = 0L,
          n_excluded = 0L,
          n_scaled = 0L,
          n_source_satisfied = 0L,
          audit_status = "no_action"
        )
      next
    }
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
    n_source_satisfied <- 0L
    if (
      action == "scale" && flag_use_source_audit
    ) {
      source_pre_match <-
        data_source_audit_current[["taxon_name"]] ==
          decision[["taxon_name"]][[1L]] &
        data_source_audit_current[["trait_domain_name"]] ==
          decision[["trait_domain_name"]][[1L]]
      if (
        !base::is.na(trait_name) && trait_name != ""
      ) {
        source_pre_match <-
          source_pre_match &
          data_source_audit_current[["trait_name"]] == trait_name
      }
      if (
        !base::is.na(dataset_id)
      ) {
        source_pre_match <-
          source_pre_match &
          data_source_audit_current[["dataset_id"]] == dataset_id
      }
      if (
        !base::is.na(value_lower)
      ) {
        if (
          base::isTRUE(
            decision[["value_lower_inclusive"]][[1L]]
          )
        ) {
          source_pre_match <-
            source_pre_match &
            data_source_audit_current[["trait_value_before"]] >=
              value_lower
        } else {
          source_pre_match <-
            source_pre_match &
            data_source_audit_current[["trait_value_before"]] >
              value_lower
        }
      }
      if (
        !base::is.na(value_upper)
      ) {
        if (
          base::isTRUE(
            decision[["value_upper_inclusive"]][[1L]]
          )
        ) {
          source_pre_match <-
            source_pre_match &
            data_source_audit_current[["trait_value_before"]] <=
              value_upper
        } else {
          source_pre_match <-
            source_pre_match &
            data_source_audit_current[["trait_value_before"]] <
              value_upper
        }
      }
      source_pre_match[base::is.na(source_pre_match)] <- FALSE
      vec_current_match_keys <-
        vec_current_record_keys[matching_records]
      source_current_match <-
        vec_source_record_keys_current %in% vec_current_match_keys
      source_relevant <- source_pre_match | source_current_match
      source_factors <-
        data_source_audit_current[["scale_factor"]][source_relevant]
      if (
        base::any(
          source_factors != decision[["scale_factor"]][[1L]]
        )
      ) {
        cli::cli_abort(
          "A taxon-scale factor conflicts with source scaling."
        )
      }
      vec_source_satisfied_keys <-
        vec_source_record_keys_current[source_relevant]
      source_satisfied_current <-
        vec_current_record_keys %in% vec_source_satisfied_keys
      matching_records <-
        matching_records & !source_satisfied_current
      matched_row_ids <-
        data_corrected[[".trait_review_row_id"]][matching_records]
      n_source_satisfied <-
        base::as.integer(base::length(vec_source_satisfied_keys))
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

    audit_status <-
      dplyr::case_when(
        action == "none" ~ "no_action",
        n_source_satisfied > 0L && n_matched == 0L ~
          "source_superseded",
        n_source_satisfied > 0L ~ "source_deduplicated",
        TRUE ~ "applied"
      )
    audit_rows[[decision_index]] <-
      tibble::tibble(
        decision_id = decision[["decision_id"]][[1L]],
        candidate_id = decision[["candidate_id"]][[1L]],
        action = action,
        n_matched = base::as.integer(n_matched),
        n_excluded = n_excluded,
        n_scaled = n_scaled,
        n_source_satisfied = n_source_satisfied,
        audit_status = audit_status
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
        n_scaled = integer(),
        n_source_satisfied = integer(),
        audit_status = character()
      )
  }

  return(
    base::list(
      data_trait_records_corrected = data_corrected,
      data_correction_audit = data_correction_audit
    )
  )
}

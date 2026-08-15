#' @title Build Trait Review Evidence Packets
#' @description
#' Builds candidate-, dataset-, and record-level evidence for automated and
#' agent-assisted trait review without changing trait records or decisions.
#' @param data_trait_records
#' Current trait records retaining source identifiers.
#' @param data_trait_review_reconciliation
#' Current reconciliation table with one row per candidate.
#' @param data_historical_review_scope
#' Historical report index with extracted summary statistics.
#' @param median_relative_tolerance
#' Maximum relative median change for a stable historical summary.
#' @param iqr_relative_tolerance
#' Maximum relative IQR change for a stable historical summary.
#' @return
#' A named list containing `data_candidate_evidence`,
#' `data_dataset_evidence`, and `data_record_evidence`.
#' @examples
#' records <- tibble::tibble(
#'   taxon_name = "Taxon A",
#'   trait_domain_name = "Diaspore mass",
#'   trait_value = 1,
#'   dataset_id = 1L,
#'   dataset_name = "Dataset A",
#'   trait_name = "Seed mass"
#' )
#' reconciliation <- tibble::tibble(
#'   candidate_id = "candidate-a",
#'   taxon_name = "Taxon A",
#'   trait_domain_name = "Diaspore mass",
#'   n_taxon_outliers = 0L,
#'   implicit_none_proposal_eligible = TRUE,
#'   historical_scope_status = "confirmed_previous_review"
#' )
#' historical <- tibble::tibble(
#'   candidate_id = "candidate-a",
#'   historical_n_records = 1L,
#'   historical_median = 1,
#'   historical_iqr = 0
#' )
#' build_trait_review_evidence_packets(
#'   records,
#'   reconciliation,
#'   historical
#' )
#' @export
build_trait_review_evidence_packets <- function(
    data_trait_records,
    data_trait_review_reconciliation,
    data_historical_review_scope,
    median_relative_tolerance = 0.01,
    iqr_relative_tolerance = 0.05) {
  list_inputs <-
    base::list(
      records = data_trait_records,
      reconciliation = data_trait_review_reconciliation,
      historical = data_historical_review_scope
    )
  assertthat::assert_that(
    base::all(purrr::map_lgl(list_inputs, base::is.data.frame)),
    msg = "All evidence-packet inputs must be data frames."
  )
  list_required_columns <-
    base::list(
      records = base::c(
        "taxon_name",
        "trait_domain_name",
        "trait_value",
        "dataset_id",
        "dataset_name",
        "sample_id",
        "trait_id",
        "taxon_id",
        "trait_name"
      ),
      reconciliation = base::c(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "n_taxon_outliers",
        "implicit_none_proposal_eligible",
        "historical_scope_status"
      ),
      historical = base::c(
        "candidate_id",
        "historical_n_records",
        "historical_median",
        "historical_iqr",
        "historical_heuristic",
        "historical_suggestion"
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
    msg = "Evidence-packet inputs are missing required columns."
  )
  assertthat::assert_that(
    base::is.numeric(median_relative_tolerance),
    base::length(median_relative_tolerance) == 1L,
    base::is.finite(median_relative_tolerance),
    median_relative_tolerance >= 0,
    base::is.numeric(iqr_relative_tolerance),
    base::length(iqr_relative_tolerance) == 1L,
    base::is.finite(iqr_relative_tolerance),
    iqr_relative_tolerance >= 0,
    msg = "Historical-summary tolerances must be finite and non-negative."
  )
  assertthat::assert_that(
    !base::anyDuplicated(
      data_trait_review_reconciliation[["candidate_id"]]
    ),
    !base::anyDuplicated(data_historical_review_scope[["candidate_id"]]),
    msg = "Candidate identifiers must be unique in candidate-level inputs."
  )

  data_candidate_keys <-
    data_trait_review_reconciliation |>
    dplyr::select(
      "candidate_id",
      "taxon_name",
      "trait_domain_name"
    )
  data_domain_record_counts <-
    data_trait_records |>
    dplyr::count(
      .data[["trait_domain_name"]],
      name = "n_domain_records"
    )
  data_record_evidence <-
    data_trait_records |>
    dplyr::inner_join(
      data_candidate_keys,
      by = dplyr::join_by(taxon_name, trait_domain_name),
      relationship = "many-to-one"
    ) |>
    dplyr::relocate(
      "candidate_id",
      .before = "taxon_name"
    ) |>
    dplyr::mutate(
      is_finite_value = base::is.finite(.data[["trait_value"]]),
      is_nonpositive_value =
        .data[["is_finite_value"]] &
        .data[["trait_value"]] <= 0
    )

  data_current_counts <-
    data_record_evidence |>
    dplyr::group_by(
      .data[["candidate_id"]],
      .data[["taxon_name"]],
      .data[["trait_domain_name"]]
    ) |>
    dplyr::summarise(
      n_records_current = dplyr::n(),
      n_finite = base::sum(.data[["is_finite_value"]]),
      n_nonfinite = base::sum(!.data[["is_finite_value"]]),
      n_nonpositive = base::sum(.data[["is_nonpositive_value"]]),
      n_datasets_current = dplyr::n_distinct(.data[["dataset_id"]]),
      n_trait_names_current = dplyr::n_distinct(.data[["trait_name"]]),
      n_unique_values = dplyr::n_distinct(.data[["trait_value"]]),
      .groups = "drop"
    )
  data_current_statistics <-
    data_record_evidence |>
    dplyr::filter(.data[["is_finite_value"]]) |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      current_minimum = base::min(.data[["trait_value"]]),
      current_lwr_25 = stats::quantile(
        .data[["trait_value"]],
        probs = 0.25,
        names = FALSE
      ),
      current_median = stats::median(.data[["trait_value"]]),
      current_upr_75 = stats::quantile(
        .data[["trait_value"]],
        probs = 0.75,
        names = FALSE
      ),
      current_iqr = stats::IQR(.data[["trait_value"]]),
      current_maximum = base::max(.data[["trait_value"]]),
      .groups = "drop"
    )
  data_dataset_evidence <-
    data_record_evidence |>
    dplyr::filter(.data[["is_finite_value"]]) |>
    dplyr::group_by(
      .data[["candidate_id"]],
      .data[["taxon_name"]],
      .data[["trait_domain_name"]],
      .data[["dataset_id"]],
      .data[["dataset_name"]],
      .data[["trait_name"]]
    ) |>
    dplyr::summarise(
      n_records_source = dplyr::n(),
      source_minimum = base::min(.data[["trait_value"]]),
      source_lwr_25 = stats::quantile(
        .data[["trait_value"]],
        probs = 0.25,
        names = FALSE
      ),
      source_median = stats::median(.data[["trait_value"]]),
      source_upr_75 = stats::quantile(
        .data[["trait_value"]],
        probs = 0.75,
        names = FALSE
      ),
      source_maximum = base::max(.data[["trait_value"]]),
      .groups = "drop"
    )
  data_unit_pattern_summary <-
    data_dataset_evidence |>
    dplyr::filter(.data[["source_median"]] > 0) |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      n_positive_source_groups = dplyr::n(),
      source_median_ratio = dplyr::if_else(
        dplyr::n() >= 2L,
        base::max(.data[["source_median"]]) /
          base::min(.data[["source_median"]]),
        NA_real_
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      unit_ratio_nearest_factor = dplyr::case_when(
        base::is.na(.data[["source_median_ratio"]]) ~ NA_real_,
        .data[["source_median_ratio"]] <= base::sqrt(10 * 100) ~ 10,
        .data[["source_median_ratio"]] <= base::sqrt(100 * 1000) ~ 100,
        TRUE ~ 1000
      ),
      unit_ratio_relative_error = base::abs(
        .data[["source_median_ratio"]] /
          .data[["unit_ratio_nearest_factor"]] -
          1
      ),
      possible_unit_pattern =
        .data[["n_positive_source_groups"]] >= 2L &
        .data[["unit_ratio_relative_error"]] <= 0.05
    )

  data_historical_statistics <-
    data_historical_review_scope |>
    dplyr::select(
      dplyr::all_of(list_required_columns[["historical"]])
    )
  data_candidate_evidence <-
    data_trait_review_reconciliation |>
    dplyr::left_join(
      data_current_counts,
      by = dplyr::join_by(
        candidate_id,
        taxon_name,
        trait_domain_name
      )
    ) |>
    dplyr::left_join(
      data_current_statistics,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_unit_pattern_summary,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_historical_statistics,
      by = dplyr::join_by(candidate_id)
    ) |>
    dplyr::left_join(
      data_domain_record_counts,
      by = dplyr::join_by(trait_domain_name)
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(
          base::c(
            "n_records_current",
            "n_finite",
            "n_nonfinite",
            "n_nonpositive",
            "n_datasets_current",
            "n_trait_names_current",
            "n_unique_values",
            "n_positive_source_groups"
          )
        ),
        ~ base::as.integer(tidyr::replace_na(.x, 0L))
      ),
      possible_unit_pattern = tidyr::replace_na(
        .data[["possible_unit_pattern"]],
        FALSE
      ),
      record_share_of_domain = dplyr::if_else(
        .data[["n_domain_records"]] > 0L,
        .data[["n_records_current"]] /
          .data[["n_domain_records"]],
        0
      ),
      outlier_fraction_current = base::pmin(
        .data[["n_taxon_outliers"]] /
          base::pmax(.data[["n_records_current"]], 1L),
        1
      ),
      historical_n_records_matches =
        !base::is.na(.data[["historical_n_records"]]) &
        .data[["n_records_current"]] ==
          .data[["historical_n_records"]],
      historical_median_relative_change = base::abs(
        .data[["current_median"]] -
          .data[["historical_median"]]
      ) /
        base::pmax(
          base::abs(.data[["historical_median"]]),
          base::.Machine[["double.eps"]]
        ),
      historical_iqr_relative_change = dplyr::if_else(
        .data[["historical_iqr"]] == 0,
        base::abs(
          .data[["current_iqr"]] -
            .data[["historical_iqr"]]
        ),
        base::abs(
          .data[["current_iqr"]] -
            .data[["historical_iqr"]]
        ) /
          base::abs(.data[["historical_iqr"]])
      ),
      historical_summary_stable =
        .data[["historical_scope_status"]] ==
          "confirmed_previous_review" &
        .data[["historical_n_records_matches"]] &
        !base::is.na(.data[["historical_median_relative_change"]]) &
        .data[["historical_median_relative_change"]] <=
          median_relative_tolerance &
        !base::is.na(.data[["historical_iqr_relative_change"]]) &
        .data[["historical_iqr_relative_change"]] <=
          iqr_relative_tolerance
    ) |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    dplyr::mutate(
      record_count_rank = dplyr::percent_rank(
        .data[["n_records_current"]]
      ),
      dataset_count_rank = dplyr::percent_rank(
        .data[["n_datasets_current"]]
      ),
      dplyr::across(
        dplyr::all_of(
          base::c("record_count_rank", "dataset_count_rank")
        ),
        ~ tidyr::replace_na(.x, 0.5)
      ),
      candidate_impact_score =
        0.5 * .data[["record_count_rank"]] +
        0.25 * .data[["dataset_count_rank"]] +
        0.25 * .data[["outlier_fraction_current"]],
      candidate_impact_tier = dplyr::case_when(
        .data[["candidate_impact_score"]] >= 0.75 ~ "high",
        .data[["candidate_impact_score"]] >= 0.4 ~ "medium",
        TRUE ~ "low"
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      evidence_packet_key = stringr::str_c(
        .data[["candidate_id"]],
        .data[["n_records_current"]],
        .data[["current_median"]],
        .data[["current_iqr"]],
        .data[["historical_n_records"]],
        .data[["historical_median"]],
        sep = "|"
      ),
      evidence_packet_id = base::vapply(
        .data[["evidence_packet_key"]],
        digest::digest,
        base::character(1L),
        algo = "sha256",
        serialize = FALSE
      )
    ) |>
    dplyr::select(-"evidence_packet_key")

  return(
    base::list(
      data_candidate_evidence = data_candidate_evidence,
      data_dataset_evidence = data_dataset_evidence,
      data_record_evidence = data_record_evidence
    )
  )
}

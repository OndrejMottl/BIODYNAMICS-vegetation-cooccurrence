#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Reconcile classified trait-review candidates
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This runner refreshes the programmatic evidence screen and records approved
#   no-action decisions only when no new non-LMA source pattern is present.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_report_directory <-
  here::here("Outputs/Reports/Trait_corrections/classified")
path_decisions <-
  here::here(
    "Data/Input/Trait_corrections/",
    "trait_review_decisions_classified.csv"
  )
path_pending_decisions <-
  here::here(
    "Data/Temp/Trait_corrections/classified/",
    "trait_review_decisions_reconciled_validated.csv"
  )
path_candidate_diagnostics <-
  base::file.path(
    path_report_directory,
    "trait_review_classified_candidate_diagnostics.csv"
  )
path_source_pairs <-
  base::file.path(
    path_report_directory,
    "trait_review_classified_source_pairs.csv"
  )
path_source_pattern_groups <-
  base::file.path(
    path_report_directory,
    "trait_review_classified_source_pattern_groups.csv"
  )
path_source_pattern_memberships <-
  base::file.path(
    path_report_directory,
    "trait_review_classified_source_pattern_memberships.csv"
  )
path_investigation_audit <-
  base::file.path(
    path_report_directory,
    "trait_review_classified_reconciliation_audit.csv"
  )
path_report <-
  base::file.path(
    path_report_directory,
    "trait_review_classified_reconciliation_report.md"
  )
evidence_reference <-
  paste0(
    "Outputs/Reports/Trait_corrections/classified/",
    "trait_review_classified_reconciliation_report.md"
  )
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )

base::dir.create(
  path_report_directory,
  recursive = TRUE,
  showWarnings = FALSE
)
base::dir.create(
  base::dirname(path_pending_decisions),
  recursive = TRUE,
  showWarnings = FALSE
)

data_prior_source_patterns <-
  if (base::file.exists(path_source_pattern_groups)) {
    readr::read_csv(
      path_source_pattern_groups,
      show_col_types = FALSE,
      progress = FALSE
    )
  } else {
    tibble::tibble(
      group_kind = character(),
      trait_domain_name = character(),
      pattern_reference = character()
    )
  }
data_trait_records_classified <-
  targets::tar_read_raw(
    name = "data_traits_classified",
    store = path_trait_store
  )
data_trait_records <-
  data_trait_records_classified |>
  dplyr::select(-"taxon_name") |>
  dplyr::rename(taxon_name = "taxon_resolved")
data_trait_records_raw <-
  targets::tar_read_raw(
    name = "data_traits_raw",
    store = path_trait_store
  )
data_trait_review_candidates <-
  targets::tar_read_raw(
    name = "data_trait_review_candidates_classified",
    store = path_trait_store
  )
data_source_scale_audit <-
  targets::tar_read_raw(
    name = "data_trait_source_scale_record_audit",
    store = path_trait_store
  )

data_reconciliation <-
  data_trait_review_candidates |>
  dplyr::mutate(
    implicit_none_proposal_eligible = FALSE,
    historical_scope_status = "not_in_historical_scope"
  )
data_historical_scope <-
  data_trait_review_candidates |>
  dplyr::transmute(
    candidate_id = .data[["candidate_id"]],
    historical_n_records = NA_integer_,
    historical_median = NA_real_,
    historical_iqr = NA_real_,
    historical_heuristic = NA_character_,
    historical_suggestion = NA_character_
  )
data_empty_proposals <-
  load_trait_review_decisions(path_decisions)

list_evidence <-
  build_trait_review_evidence_packets(
    data_trait_records = data_trait_records,
    data_trait_review_reconciliation = data_reconciliation,
    data_historical_review_scope = data_historical_scope
  )
list_diagnosis <-
  diagnose_trait_review_candidates(
    data_candidate_evidence =
      list_evidence[["data_candidate_evidence"]],
    data_record_evidence =
      list_evidence[["data_record_evidence"]],
    data_review_decision_proposals = data_empty_proposals
  )
data_empty_adjudications <-
  tibble::tibble(
    candidate_id = character(),
    review_role = character(),
    recommendation = character(),
    evidence_reference = character()
  )
list_triage <-
  build_trait_review_programmatic_triage(
    data_candidate_recommendations =
      list_diagnosis[["data_candidate_recommendations"]],
    data_approved_decisions = data_empty_proposals,
    data_proposal_diagnostics =
      list_diagnosis[["data_proposal_diagnostics"]],
    data_dataset_evidence =
      list_evidence[["data_dataset_evidence"]],
    data_record_evidence =
      list_evidence[["data_record_evidence"]],
    data_agent_adjudications = data_empty_adjudications,
    evidence_reference = evidence_reference,
    min_source_pattern_candidates = 3L,
    source_factor_relative_tolerance = 0.25,
    agent_groups_per_batch = 10L
  )
data_candidate_diagnostics <-
  list_evidence[["data_candidate_evidence"]] |>
  dplyr::left_join(
    list_diagnosis[["data_candidate_recommendations"]],
    by = dplyr::join_by(candidate_id),
    relationship = "one-to-one"
  )
data_source_pattern_groups <-
  list_triage[["data_exception_groups"]] |>
  dplyr::filter(.data[["group_kind"]] == "source_pattern")
data_source_pattern_memberships <-
  list_triage[["data_exception_memberships"]] |>
  dplyr::filter(.data[["group_kind"]] == "source_pattern")
data_novel_source_patterns <-
  data_source_pattern_groups |>
  dplyr::anti_join(
    data_prior_source_patterns |>
      dplyr::select(
        "group_kind",
        "trait_domain_name",
        "pattern_reference"
      ) |>
      dplyr::distinct(),
    by = dplyr::join_by(
      group_kind,
      trait_domain_name,
      pattern_reference
    )
  )
data_novel_non_lma_patterns <-
  data_novel_source_patterns |>
  dplyr::filter(
    .data[["trait_domain_name"]] != "Leaf mass per area"
  )

assertthat::assert_that(
  base::sum(data_candidate_diagnostics[["n_nonfinite"]]) == 0L,
  base::sum(data_candidate_diagnostics[["n_nonpositive"]]) == 0L,
  base::nrow(data_novel_non_lma_patterns) == 0L,
  msg = paste0(
    "Classified closure stopped: invalid values or a new non-LMA ",
    "source pattern requires investigation."
  )
)

data_source_rules <-
  load_trait_source_scale_rules(
    here::here(
      "Data/Input/Trait_corrections/trait_source_scale_rules.csv"
    )
  ) |>
  validate_trait_source_scale_rules(
    data_trait_records = data_trait_records_raw,
    path_vegvault = here::here("Data/Input/VegVault.sqlite")
  )
data_candidate_source_memberships <-
  data_trait_review_candidates |>
  dplyr::select(
    "candidate_id",
    "taxon_name",
    "trait_domain_name"
  ) |>
  dplyr::inner_join(
    data_trait_records |>
      dplyr::distinct(
        .data[["taxon_name"]],
        .data[["trait_domain_name"]],
        .data[["data_source_id"]]
      ),
    by = dplyr::join_by(taxon_name, trait_domain_name),
    relationship = "many-to-many"
  ) |>
  dplyr::semi_join(
    data_source_rules,
    by = dplyr::join_by(data_source_id, trait_domain_name)
  ) |>
  dplyr::select(
    "candidate_id",
    "trait_domain_name",
    "data_source_id"
  ) |>
  dplyr::distinct()
list_investigation <-
  build_trait_review_grouped_investigation(
    data_trait_review_exceptions = data_trait_review_candidates,
    data_candidate_source_memberships =
      data_candidate_source_memberships,
    data_source_scale_proposals = data_source_rules,
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-31",
    evidence_reference = evidence_reference
  )
data_decisions_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions =
      list_investigation[["data_approved_decisions"]],
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_trait_review_candidates,
    data_trait_source_scale_record_audit = data_source_scale_audit
  )
assertthat::assert_that(
  base::nrow(list_investigation[["data_pending_candidates"]]) == 0L,
  base::nrow(data_decisions_validated) ==
    base::nrow(data_trait_review_candidates),
  base::all(data_decisions_validated[["action"]] == "none"),
  msg = "Classified decisions do not close the current queue."
)

readr::write_csv(
  data_decisions_validated,
  path_pending_decisions,
  na = ""
)
data_serialized_decisions <-
  load_trait_review_decisions(path_pending_decisions)
data_serialized_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_serialized_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_trait_review_candidates,
    data_trait_source_scale_record_audit = data_source_scale_audit
  )
assertthat::assert_that(
  base::isTRUE(
    base::all.equal(
      base::as.data.frame(data_serialized_validated),
      base::as.data.frame(data_decisions_validated),
      check.attributes = FALSE
    )
  ),
  msg = "Serialized classified decisions changed after reloading."
)

data_investigation_audit <-
  list_investigation[["data_investigation_audit"]]
data_outcome_summary <-
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
vec_outcome_rows <-
  data_outcome_summary |>
  dplyr::transmute(
    report_row = stringr::str_c(
      "| ",
      .data[["trait_domain_name"]],
      " | ",
      .data[["investigation_outcome"]],
      " | ",
      .data[["n_candidates"]],
      " |"
    )
  ) |>
  dplyr::pull("report_row")
vec_report <-
  base::c(
    "# Classified trait-review reconciliation",
    "",
    "## Outcome",
    "",
    stringr::str_c(
      "The classified queue was rebuilt after all ten approved source ",
      "rules and the completed raw review. It contains ",
      base::nrow(data_trait_review_candidates),
      " candidates. Every candidate now has an approved explicit ",
      "no-action decision under the project owner's conservative policy."
    ),
    "",
    stringr::str_c(
      "The refreshed programmatic screen found no non-finite, zero, or ",
      "negative values and no new non-LMA repeated source-factor pattern. ",
      base::nrow(data_source_pattern_groups),
      " repeated source patterns remain as diagnostic coincidences already ",
      "investigated before source-rule approval."
    ),
    "",
    "| Trait domain | Outcome | Candidates |",
    "|---|---|---:|",
    vec_outcome_rows,
    "",
    "## Source corrections",
    "",
    stringr::str_c(
      "The approved source rules for sources 154, 352, 497, and 564 are ",
      "now applied before both review stages. Classified no-action ",
      "decisions therefore mean that no additional resolved-taxon ",
      "correction is supported; they do not reverse source scaling."
    ),
    "",
    "## Provisional Leaf mass per area",
    "",
    stringr::str_c(
      "TRY-derived Leaf mass per area remains provisional and unchanged. ",
      "Power-of-ten dataset comparisons in this domain are retained as ",
      "diagnostics, not promoted to corrections, because the original unit ",
      "history has not been reconstructed."
    ),
    "",
    "## Gate status",
    "",
    "The classified human-review gate is complete for the current queue.",
    "Any changed source input, candidate queue, or selector match fails closed."
  )

readr::write_csv(
  data_candidate_diagnostics,
  path_candidate_diagnostics,
  na = ""
)
readr::write_csv(
  list_triage[["data_source_pairs"]],
  path_source_pairs,
  na = ""
)
readr::write_csv(
  data_source_pattern_groups,
  path_source_pattern_groups,
  na = ""
)
readr::write_csv(
  data_source_pattern_memberships,
  path_source_pattern_memberships,
  na = ""
)
readr::write_csv(
  data_investigation_audit,
  path_investigation_audit,
  na = ""
)
base::writeLines(vec_report, con = path_report)
base::file.copy(
  from = path_pending_decisions,
  to = path_decisions,
  overwrite = TRUE
)

data_written_decisions <-
  load_trait_review_decisions(path_decisions)
assertthat::assert_that(
  base::nrow(data_written_decisions) ==
    base::nrow(data_trait_review_candidates),
  base::all(data_written_decisions[["action"]] == "none"),
  msg = "Written classified decisions are incomplete."
)
base::message(
  "Recorded ",
  base::nrow(data_written_decisions),
  " approved classified no-action decisions."
)

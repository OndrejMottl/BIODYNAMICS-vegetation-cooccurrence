#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Record interim trait-review closure
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This one-time provenance runner records the project owner's conservative
#   closure policy. Objective scale evidence remains unresolved.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_triage_directory <-
  here::here(
    "Data/Temp/Trait_corrections/raw/programmatic_triage"
  )
path_report_directory <-
  here::here("Outputs/Reports/Trait_corrections/raw")
path_decisions_raw <-
  here::here(
    "Data/Input/Trait_corrections/trait_review_decisions_raw.csv"
  )
path_spot_check_decisions <-
  here::here(
    "Data/Input/Trait_corrections/",
    "trait_review_programmatic_spot_check_decisions.csv"
  )
path_pending_decisions <-
  base::file.path(
    path_triage_directory,
    "trait_review_decisions_interim_closure_validated.csv"
  )
path_closure_audit <-
  base::file.path(
    path_report_directory,
    "trait_review_interim_closure_audit.csv"
  )
path_closure_exceptions <-
  base::file.path(
    path_report_directory,
    "trait_review_interim_closure_exceptions.csv"
  )
path_application_audit <-
  base::file.path(
    path_report_directory,
    "trait_review_interim_closure_application_audit.csv"
  )
path_closure_report <-
  base::file.path(
    path_report_directory,
    "trait_review_interim_closure_report.md"
  )
evidence_reference <-
  "Outputs/Reports/Trait_corrections/raw/trait_review_interim_closure_report.md"
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )

base::dir.create(
  path_report_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

data_trait_review_candidates <-
  targets::tar_read_raw(
    name = "data_trait_review_candidates_raw",
    store = path_trait_store
  )
data_trait_records <-
  targets::tar_read_raw(
    name = "data_traits_source_scaled",
    store = path_trait_store
  )
data_source_scale_audit <-
  targets::tar_read_raw(
    name = "data_trait_source_scale_record_audit",
    store = path_trait_store
  )
data_canonical_decisions <-
  load_trait_review_decisions(path_decisions_raw)
data_existing_decisions <-
  data_canonical_decisions |>
  dplyr::filter(
    !stringr::str_starts(
      .data[["source_reference"]],
      "interim_closure:"
    )
  )
data_spot_check_decisions <-
  readr::read_csv(
    path_spot_check_decisions,
    show_col_types = FALSE,
    progress = FALSE
  )
data_current_proposals <-
  load_trait_review_decisions(
    base::file.path(
      path_triage_directory,
      "trait_review_programmatic_decision_proposals.csv"
    )
  )
data_missing_spot_resolutions <-
  data_spot_check_decisions |>
  dplyr::filter(
    .data[["review_outcome"]] %in% base::c("approve", "reject"),
    !.data[["candidate_id"]] %in%
      data_existing_decisions[["candidate_id"]]
  )
data_spot_approvals <-
  data_missing_spot_resolutions |>
  dplyr::filter(.data[["review_outcome"]] == "approve") |>
  dplyr::select(
    "candidate_id",
    spot_reviewed_at = "reviewed_at"
  ) |>
  dplyr::inner_join(
    data_current_proposals,
    by = dplyr::join_by(candidate_id),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    evidence_reference = stringr::str_c(
      "Outputs/Reports/Trait_corrections/raw/",
      "trait_review_programmatic_spot_check_report.md"
    ),
    source_reference = stringr::str_c(
      "spot_check_exact_approval:",
      .data[["candidate_id"]]
    ),
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = base::as.character(.data[["spot_reviewed_at"]])
  ) |>
  dplyr::select(dplyr::all_of(base::names(data_existing_decisions)))
data_spot_rejections <-
  data_missing_spot_resolutions |>
  dplyr::filter(.data[["review_outcome"]] == "reject") |>
  dplyr::transmute(
    decision_key = stringr::str_c(
      .data[["candidate_id"]],
      "none",
      "spot_check_rejection_v1",
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
    candidate_id = .data[["candidate_id"]],
    taxon_name = .data[["taxon_name"]],
    trait_domain_name = .data[["trait_domain_name"]],
    trait_name = NA_character_,
    dataset_id = NA_integer_,
    value_lower = NA_real_,
    value_lower_inclusive = NA,
    value_upper = NA_real_,
    value_upper_inclusive = NA,
    action = "none",
    scale_factor = NA_real_,
    rationale = stringr::str_c(
      "Human spot check rejected the proposed scale correction; ",
      "no correction is approved."
    ),
    evidence_reference = stringr::str_c(
      "Outputs/Reports/Trait_corrections/raw/",
      "trait_review_programmatic_spot_check_report.md"
    ),
    source_reference = stringr::str_c(
      "spot_check_rejection:",
      .data[["candidate_id"]]
    ),
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = base::as.character(.data[["reviewed_at"]])
  ) |>
  dplyr::select(-"decision_key")
data_preclosure_decisions <-
  dplyr::bind_rows(
    data_existing_decisions,
    data_spot_approvals,
    data_spot_rejections
  )
data_explicit_spot_decisions <-
  data_preclosure_decisions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["source_reference"]],
      "spot_check_exact_approval:"
    ) |
      stringr::str_starts(
        .data[["source_reference"]],
        "spot_check_rejection:"
      )
  )
data_spot_check_coverage <-
  data_spot_check_decisions |>
  dplyr::left_join(
    data_preclosure_decisions |>
      dplyr::select(
        "candidate_id",
        canonical_action = "action"
      ),
    by = dplyr::join_by(candidate_id),
    relationship = "one-to-one"
  )
data_candidate_triage <-
  readr::read_csv(
    base::file.path(
      path_triage_directory,
      "trait_review_programmatic_candidate_triage.csv"
    ),
    col_select = tidyselect::all_of(
      base::c("candidate_id", "triage_outcome")
    ),
    col_types = readr::cols(.default = readr::col_character()),
    progress = FALSE
  )
data_candidate_reconciliation <-
  readr::read_csv(
    base::file.path(
      path_triage_directory,
      "trait_review_programmatic_candidate_reconciliation.csv"
    ),
    col_select = tidyselect::all_of(
      base::c("candidate_id", "reconciliation_outcome")
    ),
    col_types = readr::cols(.default = readr::col_character()),
    progress = FALSE
  )

list_closure <-
  build_trait_review_interim_closure(
    data_trait_review_candidates = data_trait_review_candidates,
    data_trait_review_decisions = data_preclosure_decisions,
    data_candidate_triage = data_candidate_triage,
    data_candidate_reconciliation =
      data_candidate_reconciliation,
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-28",
    evidence_reference = evidence_reference
  )
data_closure_audit <- list_closure[["data_closure_audit"]]
data_new_decisions <- list_closure[["data_approved_decisions"]]
data_closure_exceptions <- list_closure[["data_exceptions"]]
data_combined_decisions <-
  dplyr::bind_rows(
    data_preclosure_decisions,
    data_new_decisions
  )
data_covered_candidates <-
  data_trait_review_candidates |>
  dplyr::filter(
    .data[["candidate_id"]] %in%
      data_combined_decisions[["candidate_id"]]
  )

assertthat::assert_that(
  base::nrow(data_trait_review_candidates) == 4305L,
  base::nrow(data_preclosure_decisions) == 2433L,
  base::nrow(data_explicit_spot_decisions) == 10L,
  base::sum(
    data_explicit_spot_decisions[["action"]] == "scale"
  ) == 9L,
  base::sum(
    data_explicit_spot_decisions[["action"]] == "none"
  ) == 1L,
  base::sum(
    data_spot_check_coverage[["review_outcome"]] == "approve" &
      !base::is.na(
        data_spot_check_coverage[["canonical_action"]]
      )
  ) == 17L,
  base::sum(
    data_spot_check_coverage[["review_outcome"]] == "reject" &
      data_spot_check_coverage[["canonical_action"]] == "none",
    na.rm = TRUE
  ) == 1L,
  base::sum(
    data_spot_check_coverage[["review_outcome"]] ==
      "needs_targeted_review" &
      base::is.na(
        data_spot_check_coverage[["canonical_action"]]
      )
  ) == 6L,
  base::nrow(data_closure_audit) == 1872L,
  base::sum(data_new_decisions[["action"]] == "none") == 1479L,
  base::sum(data_new_decisions[["action"]] == "exclude") == 1L,
  base::nrow(data_closure_exceptions) == 392L,
  base::sum(
    data_spot_check_decisions[["review_outcome"]] ==
      "needs_targeted_review" &
      data_spot_check_decisions[["candidate_id"]] %in%
        data_closure_exceptions[["candidate_id"]]
  ) == 5L,
  base::nrow(data_combined_decisions) == 3913L,
  base::nrow(data_covered_candidates) == 3913L,
  !base::anyDuplicated(data_combined_decisions[["decision_id"]]),
  !base::anyDuplicated(data_combined_decisions[["candidate_id"]]),
  msg = "Interim closure no longer matches the approved snapshot."
)
data_invalid_decision <-
  data_new_decisions |>
  dplyr::filter(.data[["action"]] == "exclude")
assertthat::assert_that(
  base::nrow(data_invalid_decision) == 1L,
  data_invalid_decision[["taxon_name"]] == "Lapsana communis",
  data_invalid_decision[["trait_domain_name"]] == "Plant heigh",
  data_invalid_decision[["value_upper"]] == 0,
  data_invalid_decision[["value_upper_inclusive"]] %in% TRUE,
  msg = "The approved invalid-value exclusion has changed."
)

data_combined_decisions_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_combined_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_covered_candidates,
    data_trait_source_scale_record_audit =
      data_source_scale_audit
  )
list_application <-
  apply_trait_review_decisions(
    data_trait_records = data_trait_records,
    data_trait_review_decisions =
      data_combined_decisions_validated,
    data_trait_source_scale_record_audit =
      data_source_scale_audit
  )
data_new_application_audit <-
  list_application[["data_correction_audit"]] |>
  dplyr::filter(
    .data[["decision_id"]] %in%
      base::c(
        data_explicit_spot_decisions[["decision_id"]],
        data_new_decisions[["decision_id"]]
      )
  )
assertthat::assert_that(
  base::nrow(data_new_application_audit) == 1490L,
  base::sum(data_new_application_audit[["n_matched"]]) == 2782L,
  base::sum(data_new_application_audit[["n_excluded"]]) == 1L,
  base::sum(data_new_application_audit[["n_scaled"]]) == 2781L,
  msg = "Interim closure does not reproduce its approved record impact."
)

data_exception_summary <-
  data_closure_exceptions |>
  dplyr::mutate(
    evidence_class = dplyr::case_when(
      .data[["triage_outcome"]] ==
        "agent_repeated_source_pattern" ~
        "Repeated source pattern",
      .data[["reconciliation_outcome"]] ==
        "propose_scale_validated_threshold" ~
        "Validated threshold factor",
      .data[["reconciliation_outcome"]] ==
        "propose_scale_corroborated_source" ~
        "Corroborated source factor",
      .data[["reconciliation_outcome"]] ==
        "agent_strong_isolated_source_pattern" ~
        "Strong isolated source pattern",
      TRUE ~ "Other objective evidence"
    )
  ) |>
  dplyr::count(
    .data[["trait_domain_name"]],
    .data[["evidence_class"]],
    name = "n_candidates"
  ) |>
  dplyr::arrange(
    .data[["trait_domain_name"]],
    .data[["evidence_class"]]
  )
vec_closure_table <-
  list_closure[["data_closure_summary"]] |>
  dplyr::transmute(
    report_row = stringr::str_c(
      "| ",
      .data[["trait_domain_name"]],
      " | ",
      .data[["closure_outcome"]],
      " | ",
      .data[["n_candidates"]],
      " |"
    )
  ) |>
  dplyr::pull("report_row")
vec_exception_table <-
  data_exception_summary |>
  dplyr::transmute(
    report_row = stringr::str_c(
      "| ",
      .data[["trait_domain_name"]],
      " | ",
      .data[["evidence_class"]],
      " | ",
      .data[["n_candidates"]],
      " |"
    )
  ) |>
  dplyr::pull("report_row")
vec_report <-
  base::c(
    "# Interim trait-review closure",
    "",
    "## Outcome",
    "",
    stringr::str_c(
      "The current raw review queue contains 4,305 taxon-trait ",
      "candidates. Existing approved decisions cover 2,423 candidates. ",
      "This workflow also records nine exact scale approvals and one ",
      "rejected scale proposal from the prior 24-case human review. It ",
      "then records 1,479 additional approved no-action decisions after ",
      "structured investigation and one narrow exclusion for a nonpositive ",
      "Plant heigh value in Lapsana communis."
    ),
    "",
    stringr::str_c(
      "No scale proposal beyond those nine explicit human approvals is ",
      "approved by this workflow. The remaining 392 candidates have ",
      "objective scale or source-pattern evidence and remain unresolved ",
      "for grouped programmatic investigation. The production raw-review ",
      "gate therefore remains intentionally incomplete."
    ),
    "",
    "| Trait domain | Closure outcome | Candidates |",
    "|---|---|---:|",
    vec_closure_table,
    "",
    "## Remaining objective-evidence exceptions",
    "",
    "| Trait domain | Evidence class | Candidates |",
    "|---|---|---:|",
    vec_exception_table,
    "",
    stringr::str_c(
      "The exception queue is not a request for another broad manual ",
      "review. Its repeated patterns should be investigated by source, ",
      "trait definition, and proposed unit factor. Only corroborated ",
      "source-level or atomic correction rules should be promoted; ",
      "otherwise the standing conservative policy resolves the ",
      "investigated candidate to no action."
    ),
    "",
    stringr::str_c(
      "Leaf mass per area remains provisional. This closure does not ",
      "alter TRY-derived values or treat distributional factor patterns ",
      "as proof of a unit correction."
    ),
    "",
    "## Provenance and safeguards",
    "",
    "- Approved by OndrejMottl on 2026-08-28.",
    "- Input records are the source-scaled VegVault 1.0.0 trait records.",
    "- Candidate identities come from the cached production raw-review target.",
    "- All combined decisions were validated in memory before writing.",
    stringr::str_c(
      "- The nine exact human-approved scale rules match and scale 2,781 ",
      "current records."
    ),
    stringr::str_c(
      "- The rejected scale proposal is recorded as an explicit no-action ",
      "decision."
    ),
    "- The 1,479 no-action decisions match and change zero records.",
    stringr::str_c(
      "- The Lapsana communis exclusion matches and excludes exactly ",
      "one value at or below zero."
    ),
    stringr::str_c(
      "- The 392 objective-evidence candidates are excluded from ",
      "automatic approval."
    )
  )

readr::write_csv(
  data_combined_decisions,
  path_pending_decisions,
  na = ""
)
data_pending_decisions <-
  load_trait_review_decisions(path_pending_decisions)
data_pending_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_pending_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_covered_candidates,
    data_trait_source_scale_record_audit =
      data_source_scale_audit
  )
assertthat::assert_that(
  base::isTRUE(
    base::all.equal(
      base::as.data.frame(data_pending_validated),
      base::as.data.frame(data_combined_decisions_validated),
      check.attributes = FALSE
    )
  ),
  msg = "Serialized closure decisions differ from validated decisions."
)

readr::write_csv(data_closure_audit, path_closure_audit, na = "")
readr::write_csv(
  data_closure_exceptions,
  path_closure_exceptions,
  na = ""
)
readr::write_csv(
  data_new_application_audit,
  path_application_audit,
  na = ""
)
base::writeLines(vec_report, con = path_closure_report)
base::file.copy(
  from = path_pending_decisions,
  to = path_decisions_raw,
  overwrite = TRUE
)

data_written_decisions <-
  load_trait_review_decisions(path_decisions_raw)
data_written_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_written_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_covered_candidates,
    data_trait_source_scale_record_audit =
      data_source_scale_audit
  )
assertthat::assert_that(
  base::isTRUE(
    base::all.equal(
      base::as.data.frame(data_written_validated),
      base::as.data.frame(data_combined_decisions_validated),
      check.attributes = FALSE
    )
  ),
  msg = "Written decisions differ from validated closure decisions."
)

base::message(
  "Recorded nine exact reviewed scales, one reviewed rejection, 1,479 ",
  "conservative no-action decisions, and one invalid-value exclusion; ",
  "392 objective-evidence candidates remain unresolved."
)

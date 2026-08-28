#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Record supported trait-scale approvals
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This one-time provenance runner records the project owner's explicit
#   approval of the four unanimously supported scale-rule strata.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_triage <-
  here::here(
    "Data/Temp/Trait_corrections/raw/programmatic_triage"
  )
path_proposals <-
  base::file.path(
    path_triage,
    "trait_review_programmatic_decision_proposals.csv"
  )
path_proposal_audit <-
  base::file.path(
    path_triage,
    "trait_review_programmatic_proposal_audit.csv"
  )
path_stratum_assessment <-
  base::file.path(
    path_triage,
    "trait_review_programmatic_spot_check_stratum_assessment.csv"
  )
path_decisions_raw <-
  here::here(
    "Data/Input/Trait_corrections/trait_review_decisions_raw.csv"
  )
path_approval_audit <-
  here::here(
    "Outputs/Reports/Trait_corrections/raw/",
    "trait_review_supported_scale_approval_audit.csv"
  )
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )
evidence_reference <-
  stringr::str_c(
    "Outputs/Reports/Trait_corrections/raw/",
    "trait_review_programmatic_spot_check_report.md"
  )

data_proposals <-
  load_trait_review_decisions(path_proposals) |>
  dplyr::filter(.data[["action"]] == "scale") |>
  dplyr::mutate(
    rule_kind = dplyr::if_else(
      base::is.na(.data[["value_lower"]]) &
        base::is.na(.data[["value_upper"]]),
      "dataset_specific",
      "threshold"
    ),
    threshold_direction = dplyr::case_when(
      !base::is.na(.data[["value_lower"]]) ~ "above",
      !base::is.na(.data[["value_upper"]]) ~ "below",
      TRUE ~ NA_character_
    ),
    rule_stratum = stringr::str_glue(
      "{.data[['trait_domain_name']]}|{.data[['rule_kind']]}|",
      "{tidyr::replace_na(.data[['threshold_direction']], 'source')}|",
      "factor={.data[['scale_factor']]}"
    )
  )
data_proposal_audit <-
  readr::read_csv(
    path_proposal_audit,
    show_col_types = FALSE,
    progress = FALSE
  )
data_supported_strata <-
  readr::read_csv(
    path_stratum_assessment,
    show_col_types = FALSE,
    progress = FALSE
  ) |>
  dplyr::filter(
    .data[["expansion_assessment"]] ==
      "supports_conservative_expansion"
  )
data_supported_proposals <-
  data_proposals |>
  dplyr::semi_join(
    data_supported_strata,
    by = dplyr::join_by(rule_stratum)
  )
data_supported_proposal_audit <-
  data_supported_proposals |>
  dplyr::select(
    "decision_id",
    "candidate_id",
    "taxon_name",
    "trait_domain_name",
    "scale_factor",
    "rule_stratum"
  ) |>
  dplyr::left_join(
    data_proposal_audit |>
      dplyr::select(
        "decision_id",
        "proposed_record_count"
    ),
    by = dplyr::join_by(decision_id),
    relationship = "one-to-one"
  )

assertthat::assert_that(
  base::nrow(data_supported_strata) == 4L,
  base::nrow(data_supported_proposals) == 50L,
  base::all(
    !base::is.na(
      data_supported_proposal_audit[["proposed_record_count"]]
    )
  ),
  base::sum(
    data_supported_proposal_audit[["proposed_record_count"]]
  ) == 3301L,
  base::all(
    data_supported_proposals[["review_status"]] == "proposed"
  ),
  base::all(data_supported_proposals[["action"]] == "scale"),
  !base::anyDuplicated(data_supported_proposals[["candidate_id"]]),
  msg = "Supported scale proposals no longer match the approved snapshot."
)

data_existing_decisions <-
  load_trait_review_decisions(path_decisions_raw)
assertthat::assert_that(
  base::nrow(data_existing_decisions) == 2372L,
  base::sum(data_existing_decisions[["action"]] == "none") == 2353L,
  base::sum(data_existing_decisions[["action"]] == "exclude") == 19L,
  base::sum(data_existing_decisions[["action"]] == "scale") == 0L,
  !base::any(
    data_supported_proposals[["candidate_id"]] %in%
      data_existing_decisions[["candidate_id"]]
  ),
  msg = "Canonical raw decisions no longer match the pre-approval snapshot."
)

data_new_approved_decisions <-
  data_supported_proposals |>
  dplyr::select(-"rule_kind", -"threshold_direction", -"rule_stratum") |>
  dplyr::mutate(
    evidence_reference = evidence_reference,
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-27"
  )
data_approved_decisions <-
  dplyr::bind_rows(
    data_existing_decisions,
    data_new_approved_decisions
  )
assertthat::assert_that(
  base::nrow(data_approved_decisions) == 2422L,
  base::sum(data_approved_decisions[["action"]] == "none") == 2353L,
  base::sum(data_approved_decisions[["action"]] == "exclude") == 19L,
  base::sum(data_approved_decisions[["action"]] == "scale") == 50L,
  !base::anyDuplicated(data_approved_decisions[["decision_id"]]),
  !base::anyDuplicated(data_approved_decisions[["candidate_id"]]),
  msg = "Combined approvals do not match the authorized decision set."
)

data_trait_records <-
  targets::tar_read_raw(
    name = "data_traits_raw",
    store = path_trait_store
  )
data_source_candidates <-
  load_review_submission_candidates(
    path_review_submission = here::here(
      "Data/Input/Trait_corrections/Review_submission/",
      "trait_manual_corrections.csv"
    )
  )
data_trait_review_candidates <-
  build_trait_review_candidates(
    data_trait_records = data_trait_records,
    data_source_candidates = data_source_candidates,
    review_stage = "raw"
  )
data_approved_candidates <-
  data_trait_review_candidates |>
  dplyr::filter(
    .data[["candidate_id"]] %in%
      data_approved_decisions[["candidate_id"]]
  )
data_approved_decisions_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_approved_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_approved_candidates
  )
list_application <-
  apply_trait_review_decisions(
    data_trait_records = data_trait_records,
    data_trait_review_decisions =
      data_approved_decisions_validated
  )
data_application_audit <-
  list_application[["data_correction_audit"]]
data_new_application_audit <-
  data_application_audit |>
  dplyr::filter(
    .data[["decision_id"]] %in%
      data_new_approved_decisions[["decision_id"]]
  )

assertthat::assert_that(
  base::nrow(data_approved_candidates) == 2422L,
  base::sum(data_application_audit[["n_excluded"]]) == 15864L,
  base::sum(data_application_audit[["n_scaled"]]) == 3301L,
  base::nrow(data_new_application_audit) == 50L,
  base::all(data_new_application_audit[["n_scaled"]] > 0L),
  base::sum(data_new_application_audit[["n_scaled"]]) == 3301L,
  msg = "Approved scale rules do not reproduce the authorized impact."
)

data_approval_audit <-
  data_supported_proposal_audit |>
  dplyr::left_join(
    data_new_application_audit |>
      dplyr::select(
        "decision_id",
        "n_matched",
        "n_scaled"
      ),
    by = dplyr::join_by(decision_id),
    unmatched = "error",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    record_count_matches =
      .data[["proposed_record_count"]] == .data[["n_scaled"]],
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-27",
    evidence_reference = evidence_reference
  )
assertthat::assert_that(
  base::all(data_approval_audit[["record_count_matches"]]),
  msg = "Approval audit differs from the reviewed proposal impact."
)

readr::write_csv(
  data_approved_decisions,
  path_decisions_raw,
  na = ""
)
readr::write_csv(
  data_approval_audit,
  path_approval_audit,
  na = ""
)

data_written_decisions <-
  load_trait_review_decisions(path_decisions_raw)
data_written_decisions_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_written_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_approved_candidates
  )
assertthat::assert_that(
  base::isTRUE(
    base::all.equal(
      base::as.data.frame(data_written_decisions_validated),
      base::as.data.frame(data_approved_decisions_validated),
      check.attributes = FALSE
    )
  ),
  msg = "Written decisions differ from the validated approval set."
)

base::message(
  "Recorded 50 approved scale decisions affecting 3,301 current records."
)

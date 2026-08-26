#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Run programmatic trait-review triage
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This workflow writes proposals and grouped evidence only. It never approves
#   a decision, applies a correction, or launches an agent.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_raw_directory <-
  here::here("Data/Temp/Trait_corrections/raw")
path_output_directory <-
  base::file.path(path_raw_directory, "programmatic_triage")
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )
path_accepted_adjudications <-
  here::here(
    "Outputs/Reports/Trait_corrections/raw/review_evidence/",
    "pilot/accepted"
  )
path_decisions_raw <-
  here::here(
    "Data/Input/Trait_corrections/trait_review_decisions_raw.csv"
  )
evidence_reference <-
  stringr::str_c(
    "Outputs/Reports/Trait_corrections/raw/",
    "trait_review_programmatic_triage_report.md"
  )

base::dir.create(
  path_output_directory,
  recursive = TRUE,
  showWarnings = FALSE
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
data_historical_scope <-
  readr::read_csv(
    base::file.path(
      path_raw_directory,
      "historical_review_scope.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
data_submission_audit <-
  readr::read_csv(
    base::file.path(
      path_raw_directory,
      "review_submission_audit.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
data_recovered_proposals <-
  readr::read_csv(
    base::file.path(
      path_raw_directory,
      "review_decision_proposals.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
data_reconciliation <-
  build_trait_review_reconciliation(
    data_trait_review_candidates = data_trait_review_candidates,
    data_historical_review_scope = data_historical_scope,
    data_review_submission_audit = data_submission_audit,
    data_review_decision_proposals = data_recovered_proposals
  )
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
    data_review_decision_proposals = data_recovered_proposals
  )
data_approved_decisions <-
  load_trait_review_decisions(path_decisions_raw)

vec_adjudication_files <-
  base::list.files(
    path = path_accepted_adjudications,
    pattern = "_adjudicator_.*[.]csv$",
    full.names = TRUE
  )
if (
  base::length(vec_adjudication_files) == 0L
) {
  data_agent_adjudications <-
    tibble::tibble(
      candidate_id = character(),
      review_role = character(),
      recommendation = character(),
      evidence_reference = character()
    )
} else {
  data_agent_adjudications <-
    vec_adjudication_files |>
    purrr::map(
      ~ readr::read_csv(
        .x,
        show_col_types = FALSE,
        progress = FALSE
      )
    ) |>
    purrr::list_rbind()
}

list_triage <-
  build_trait_review_programmatic_triage(
    data_candidate_recommendations =
      list_diagnosis[["data_candidate_recommendations"]],
    data_approved_decisions = data_approved_decisions,
    data_proposal_diagnostics =
      list_diagnosis[["data_proposal_diagnostics"]],
    data_dataset_evidence =
      list_evidence[["data_dataset_evidence"]],
    data_record_evidence =
      list_evidence[["data_record_evidence"]],
    data_agent_adjudications = data_agent_adjudications,
    evidence_reference = evidence_reference,
    min_source_pattern_candidates = 3L,
    source_factor_relative_tolerance = 0.25,
    agent_groups_per_batch = 10L
  )
data_candidate_triage <-
  list_triage[["data_candidate_triage"]]
vec_exception_candidate_ids <-
  data_candidate_triage |>
  dplyr::filter(.data[["requires_agent"]]) |>
  dplyr::pull(.data[["candidate_id"]])

list_outputs <-
  base::list(
    trait_review_programmatic_candidate_triage =
      data_candidate_triage,
    trait_review_programmatic_none_proposals =
      list_triage[["data_none_proposals"]],
    trait_review_programmatic_exception_memberships =
      list_triage[["data_exception_memberships"]],
    trait_review_programmatic_exception_groups =
      list_triage[["data_exception_groups"]],
    trait_review_programmatic_agent_group_queue =
      list_triage[["data_agent_group_queue"]],
    trait_review_programmatic_source_pairs =
      list_triage[["data_source_pairs"]],
    trait_review_programmatic_summary =
      list_triage[["data_triage_summary"]],
    trait_review_programmatic_cost_gate =
      list_triage[["data_cost_gate"]],
    trait_review_programmatic_exception_datasets =
      list_evidence[["data_dataset_evidence"]] |>
      dplyr::filter(
        .data[["candidate_id"]] %in% vec_exception_candidate_ids
      ),
    trait_review_programmatic_exception_records =
      list_evidence[["data_record_evidence"]] |>
      dplyr::filter(
        .data[["candidate_id"]] %in% vec_exception_candidate_ids
      ),
    trait_review_programmatic_exception_proposals =
      list_diagnosis[["data_proposal_diagnostics"]] |>
      dplyr::filter(
        .data[["candidate_id"]] %in% vec_exception_candidate_ids
      ),
    trait_review_programmatic_completed_adjudications =
      data_agent_adjudications
  )

purrr::iwalk(
  list_outputs,
  ~ readr::write_csv(
    .x,
    base::file.path(
      path_output_directory,
      stringr::str_c(.y, ".csv")
    ),
    na = ""
  )
)

list_triage[["data_cost_gate"]] |>
  base::print()
base::message(
  "Wrote non-mutating programmatic triage outputs to ",
  path_output_directory,
  "."
)

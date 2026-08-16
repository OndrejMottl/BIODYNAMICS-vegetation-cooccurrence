#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#           Run trait-review policy workflow
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This workflow writes proposals and diagnostics only. It never approves or
#   applies a decision and never edits either canonical decision file.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_input_directory <-
  here::here("Data/Temp/Trait_corrections/raw")
path_output_directory <-
  base::file.path(path_input_directory, "policy")
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )
evidence_reference <-
  stringr::str_c(
    "Outputs/Reports/Trait_corrections/raw/",
    "trait_review_policy_report.md"
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
      path_input_directory,
      "historical_review_scope.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
data_submission_audit <-
  readr::read_csv(
    base::file.path(
      path_input_directory,
      "review_submission_audit.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
data_recovered_proposals <-
  readr::read_csv(
    base::file.path(
      path_input_directory,
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
data_candidate_recommendations <-
  list_diagnosis[["data_candidate_recommendations"]] |>
  dplyr::arrange(
    .data[["trait_domain_name"]],
    dplyr::desc(.data[["candidate_impact_score"]]),
    .data[["taxon_name"]]
  )
list_policy_outputs <-
  build_trait_review_policy_outputs(
    data_candidate_recommendations =
      data_candidate_recommendations,
    evidence_reference = evidence_reference,
    max_agent_candidates_per_domain = 25L,
    agent_batch_size = 25L
  )

data_policy_proposals <-
  list_policy_outputs[["data_policy_proposals"]]
data_agent_review_queue <-
  list_policy_outputs[["data_agent_review_queue"]]
data_policy_summary <-
  list_policy_outputs[["data_policy_summary"]]
vec_targeted_candidate_ids <-
  base::unique(
    base::c(
      data_agent_review_queue[["candidate_id"]],
      data_policy_proposals[["candidate_id"]][
        data_policy_proposals[["action"]] == "exclude"
      ]
    )
  )
data_targeted_dataset_evidence <-
  list_evidence[["data_dataset_evidence"]] |>
  dplyr::filter(
    .data[["candidate_id"]] %in% vec_targeted_candidate_ids
  )
data_targeted_record_evidence <-
  list_evidence[["data_record_evidence"]] |>
  dplyr::filter(
    .data[["candidate_id"]] %in% vec_targeted_candidate_ids
  )

data_exclusion_keys <-
  data_policy_proposals |>
  dplyr::filter(.data[["action"]] == "exclude") |>
  dplyr::select("taxon_name", "trait_domain_name") |>
  dplyr::distinct() |>
  dplyr::mutate(has_policy_exclusion = TRUE)
data_distribution_scenarios <-
  data_trait_records |>
  dplyr::left_join(
    data_exclusion_keys,
    by = dplyr::join_by(taxon_name, trait_domain_name),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    has_policy_exclusion = tidyr::replace_na(
      .data[["has_policy_exclusion"]],
      FALSE
    ),
    proposed_exclusion =
      .data[["has_policy_exclusion"]] &
      base::is.finite(.data[["trait_value"]]) &
      .data[["trait_value"]] <= 0
  ) |>
  dplyr::group_by(.data[["trait_domain_name"]]) |>
  dplyr::summarise(
    n_records_before = dplyr::n(),
    n_records_proposed_excluded = base::sum(
      .data[["proposed_exclusion"]]
    ),
    n_records_after =
      .data[["n_records_before"]] -
      .data[["n_records_proposed_excluded"]],
    minimum_before = base::min(.data[["trait_value"]], na.rm = TRUE),
    median_before = stats::median(
      .data[["trait_value"]],
      na.rm = TRUE
    ),
    maximum_before = base::max(.data[["trait_value"]], na.rm = TRUE),
    minimum_after = base::min(
      .data[["trait_value"]][!.data[["proposed_exclusion"]]],
      na.rm = TRUE
    ),
    median_after = stats::median(
      .data[["trait_value"]][!.data[["proposed_exclusion"]]],
      na.rm = TRUE
    ),
    maximum_after = base::max(
      .data[["trait_value"]][!.data[["proposed_exclusion"]]],
      na.rm = TRUE
    ),
    .groups = "drop"
  )

list_outputs <-
  base::list(
    trait_review_policy_candidates = data_trait_review_candidates,
    trait_review_policy_reconciliation = data_reconciliation,
    trait_review_policy_candidate_evidence =
      list_evidence[["data_candidate_evidence"]],
    trait_review_policy_candidate_recommendations =
      data_candidate_recommendations,
    trait_review_policy_proposal_diagnostics =
      list_diagnosis[["data_proposal_diagnostics"]],
    trait_review_policy_proposals = data_policy_proposals,
    trait_review_policy_agent_queue = data_agent_review_queue,
    trait_review_policy_summary = data_policy_summary,
    trait_review_policy_distribution_scenarios =
      data_distribution_scenarios,
    trait_review_policy_targeted_dataset_evidence =
      data_targeted_dataset_evidence,
    trait_review_policy_targeted_record_evidence =
      data_targeted_record_evidence
  )

purrr::iwalk(
  list_outputs,
  ~ readr::write_csv(
    .x,
    base::file.path(
      path_output_directory,
      stringr::str_c(.y, ".csv")
    )
  )
)

data_policy_summary |>
  base::print(n = Inf)
base::message(
  "Wrote non-mutating all-domain policy outputs to ",
  path_output_directory,
  "."
)

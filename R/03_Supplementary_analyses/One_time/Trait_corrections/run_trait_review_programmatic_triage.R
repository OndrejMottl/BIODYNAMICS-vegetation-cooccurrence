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
list_programmatic_reconciliation <-
  build_trait_review_programmatic_reconciliation(
    data_candidate_triage = data_candidate_triage,
    data_source_pairs = list_triage[["data_source_pairs"]],
    data_submission_audit = data_submission_audit,
    data_record_evidence =
      list_evidence[["data_record_evidence"]],
    evidence_reference = evidence_reference
  )
data_scale_proposals <-
  list_programmatic_reconciliation[["data_decision_proposals"]] |>
  dplyr::filter(.data[["action"]] == "scale") |>
  dplyr::left_join(
    list_programmatic_reconciliation[[
      "data_candidate_reconciliation"
    ]] |>
      dplyr::select(
        -"taxon_name",
        -"trait_domain_name"
      ),
    by = dplyr::join_by(candidate_id)
  ) |>
  dplyr::left_join(
    list_programmatic_reconciliation[["data_proposal_audit"]] |>
      dplyr::select(
        "candidate_id",
        "proposed_record_count"
      ),
    by = dplyr::join_by(candidate_id),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    gap_improvement =
      .data[["threshold_gap_before"]] -
        .data[["threshold_gap_after"]]
  )
data_threshold_spot_check_pool <-
  data_scale_proposals |>
  dplyr::filter(
    .data[["reconciliation_outcome"]] ==
      "propose_scale_validated_threshold"
  ) |>
  dplyr::arrange(.data[["candidate_id"]]) |>
  dplyr::group_by(
    .data[["trait_domain_name"]],
    .data[["scale_factor"]],
    .data[["threshold_direction"]]
  ) |>
  dplyr::mutate(
    flag_rule_stratum = dplyr::row_number() == 1L
  ) |>
  dplyr::ungroup() |>
  dplyr::group_by(.data[["trait_domain_name"]]) |>
  dplyr::mutate(
    flag_min_records =
      .data[["proposed_record_count"]] ==
        base::min(.data[["proposed_record_count"]]),
    flag_max_records =
      .data[["proposed_record_count"]] ==
        base::max(.data[["proposed_record_count"]]),
    flag_min_gap_before =
      .data[["threshold_gap_before"]] ==
        base::min(.data[["threshold_gap_before"]]),
    flag_max_gap_before =
      .data[["threshold_gap_before"]] ==
        base::max(.data[["threshold_gap_before"]]),
    flag_max_gap_after =
      .data[["threshold_gap_after"]] ==
        base::max(.data[["threshold_gap_after"]]),
    flag_max_impact =
      .data[["candidate_impact_score"]] ==
        base::max(.data[["candidate_impact_score"]]),
    selection_score =
      100L * .data[["flag_rule_stratum"]] +
        10L * .data[["flag_min_records"]] +
        10L * .data[["flag_max_records"]] +
        5L * .data[["flag_min_gap_before"]] +
        5L * .data[["flag_max_gap_before"]] +
        5L * .data[["flag_max_gap_after"]] +
        5L * .data[["flag_max_impact"]],
    selection_reason = dplyr::case_when(
      .data[["flag_rule_stratum"]] ~
        "Representative of a factor and threshold-direction stratum",
      .data[["flag_max_records"]] ~
        "Largest proposed record impact in the trait domain",
      .data[["flag_min_records"]] ~
        "Smallest proposed record impact in the trait domain",
      .data[["flag_max_gap_before"]] ~
        "Largest before-correction median gap in the trait domain",
      .data[["flag_min_gap_before"]] ~
        "Smallest accepted before-correction gap in the trait domain",
      .data[["flag_max_gap_after"]] ~
        "Largest residual median gap after correction",
      .data[["flag_max_impact"]] ~
        "Highest candidate impact score in the trait domain",
      TRUE ~ "Stable-hash fill for trait-domain coverage"
    ),
    n_domain_cases = dplyr::case_when(
      .data[["trait_domain_name"]] == "Leaf Area" ~ 9L,
      .data[["trait_domain_name"]] ==
        "Leaf nitrogen content per unit mass" ~ 8L,
      .data[["trait_domain_name"]] == "Plant heigh" ~ 5L,
      TRUE ~ 0L
    )
  ) |>
  dplyr::arrange(
    dplyr::desc(.data[["selection_score"]]),
    .data[["candidate_id"]],
    .by_group = TRUE
  ) |>
  dplyr::filter(dplyr::row_number() <= .data[["n_domain_cases"]]) |>
  dplyr::ungroup()
data_source_spot_check_pool <-
  data_scale_proposals |>
  dplyr::filter(
    .data[["reconciliation_outcome"]] ==
      "propose_scale_corroborated_source"
  ) |>
  dplyr::mutate(
    selection_score = 1000L,
    selection_reason =
      "All independently corroborated dataset-specific proposals"
  )
data_programmatic_spot_check <-
  dplyr::bind_rows(
    data_source_spot_check_pool,
    data_threshold_spot_check_pool
  ) |>
  dplyr::arrange(
    .data[["trait_domain_name"]],
    .data[["reconciliation_outcome"]],
    .data[["scale_factor"]],
    .data[["candidate_id"]]
  ) |>
  dplyr::mutate(
    spot_check_id = stringr::str_glue(
      "SC-{stringr::str_pad(dplyr::row_number(), 2L, pad = '0')}"
    ),
    reviewer_decision = "",
    reviewer_notes = ""
  ) |>
  dplyr::select(
    "spot_check_id",
    "selection_reason",
    "reviewer_decision",
    "reviewer_notes",
    dplyr::everything()
  )
data_programmatic_spot_check_records <-
  list_evidence[["data_record_evidence"]] |>
  dplyr::inner_join(
    data_programmatic_spot_check |>
      dplyr::select(
        "spot_check_id",
        "candidate_id",
        trait_name_rule = "trait_name",
        dataset_id_rule = "dataset_id",
        "value_lower",
        "value_lower_inclusive",
        "value_upper",
        "value_upper_inclusive",
        "scale_factor"
      ),
    by = dplyr::join_by(candidate_id),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    selected_for_scaling =
      (base::is.na(.data[["trait_name_rule"]]) |
        .data[["trait_name"]] == .data[["trait_name_rule"]]) &
      (base::is.na(.data[["dataset_id_rule"]]) |
        .data[["dataset_id"]] == .data[["dataset_id_rule"]]) &
      (base::is.na(.data[["value_lower"]]) |
        .data[["trait_value"]] > .data[["value_lower"]] |
        (.data[["value_lower_inclusive"]] %in% TRUE &
          .data[["trait_value"]] == .data[["value_lower"]])) &
      (base::is.na(.data[["value_upper"]]) |
        .data[["trait_value"]] < .data[["value_upper"]] |
        (.data[["value_upper_inclusive"]] %in% TRUE &
          .data[["trait_value"]] == .data[["value_upper"]])),
    trait_value_after = dplyr::if_else(
      .data[["selected_for_scaling"]],
      .data[["trait_value"]] * .data[["scale_factor"]],
      .data[["trait_value"]]
    )
  )
assertthat::assert_that(
  base::nrow(data_programmatic_spot_check) >= 20L,
  base::nrow(data_programmatic_spot_check) <= 30L,
  base::all(
    base::c(
      "Leaf Area",
      "Leaf nitrogen content per unit mass",
      "Plant heigh"
    ) %in% data_programmatic_spot_check[["trait_domain_name"]]
  ),
  base::sum(
    data_programmatic_spot_check[["reconciliation_outcome"]] ==
      "propose_scale_corroborated_source"
  ) == 2L,
  msg = "The scale-proposal spot check must retain its coverage contract."
)
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
    trait_review_programmatic_candidate_reconciliation =
      list_programmatic_reconciliation[[
        "data_candidate_reconciliation"
      ]],
    trait_review_programmatic_decision_proposals =
      list_programmatic_reconciliation[[
        "data_decision_proposals"
      ]],
    trait_review_programmatic_proposal_audit =
      list_programmatic_reconciliation[[
        "data_proposal_audit"
      ]],
    trait_review_programmatic_reconciliation_summary =
      list_programmatic_reconciliation[[
        "data_reconciliation_summary"
      ]],
    trait_review_programmatic_spot_check =
      data_programmatic_spot_check,
    trait_review_programmatic_spot_check_records =
      data_programmatic_spot_check_records,
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

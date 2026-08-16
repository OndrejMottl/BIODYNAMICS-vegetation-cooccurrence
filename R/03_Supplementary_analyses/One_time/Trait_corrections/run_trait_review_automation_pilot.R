#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#          Run trait-review automation pilot
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This dry run writes diagnostics only. It never edits canonical decisions.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

vec_pilot_domains <-
  base::c("Diaspore mass", "Stem specific density")
path_input_directory <-
  here::here("Data/Temp/Trait_corrections/raw")
path_output_directory <-
  base::file.path(path_input_directory, "automation")
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
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
  ) |>
  dplyr::filter(
    .data[["trait_domain_name"]] %in% vec_pilot_domains
  )
data_reconciliation <-
  readr::read_csv(
    base::file.path(
      path_input_directory,
      "trait_review_reconciliation.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
  dplyr::filter(
    .data[["trait_domain_name"]] %in% vec_pilot_domains
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
data_proposals <-
  readr::read_csv(
    base::file.path(
      path_input_directory,
      "review_decision_proposals.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
  dplyr::filter(
    .data[["trait_domain_name"]] %in% vec_pilot_domains
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
    data_review_decision_proposals = data_proposals
  )

data_candidate_recommendations <-
  list_diagnosis[["data_candidate_recommendations"]] |>
  dplyr::arrange(
    .data[["trait_domain_name"]],
    dplyr::desc(.data[["candidate_impact_score"]]),
    .data[["taxon_name"]]
  ) |>
  dplyr::group_by(.data[["trait_domain_name"]]) |>
  dplyr::mutate(
    agent_review_order = base::cumsum(
      .data[["acceptance_eligibility"]] ==
        "requires_agent_review"
    ),
    batch_number = dplyr::if_else(
      .data[["acceptance_eligibility"]] ==
        "requires_agent_review",
      base::as.integer(
        base::ceiling(.data[["agent_review_order"]] / 25)
      ),
      NA_integer_
    ),
    agent_batch_id = dplyr::if_else(
      !base::is.na(.data[["batch_number"]]),
      stringr::str_c(
        stringr::str_replace_all(
          stringr::str_to_lower(.data[["trait_domain_name"]]),
          "[^a-z0-9]+",
          "_"
        ),
        stringr::str_pad(
          .data[["batch_number"]],
          width = 2L,
          pad = "0"
        ),
        sep = "_"
      ),
      NA_character_
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-"agent_review_order")

data_historical_comparison <-
  data_candidate_recommendations |>
  dplyr::mutate(
    historical_comparison = dplyr::case_when(
      base::is.na(.data[["historical_heuristic"]]) ~
        "no_historical_candidate",
      .data[["historical_heuristic"]] == "PROBABLY OK" &
        .data[["deterministic_outcome"]] ==
          "retain_historical_no_action" ~
        "aligned_no_action",
      .data[["historical_heuristic"]] == "SCALE ISSUE" &
        .data[["deterministic_outcome"]] %in%
          base::c(
            "investigate_unit_pattern",
            "validate_recovered_proposal"
          ) ~
        "aligned_scale_review",
      .data[["historical_heuristic"]] == "REVIEW" &
        .data[["acceptance_eligibility"]] ==
          "requires_agent_review" ~
        "aligned_review",
      TRUE ~ "changed_or_more_conservative"
    )
  ) |>
  dplyr::select(
    "candidate_id",
    "taxon_name",
    "trait_domain_name",
    "agent_batch_id",
    "historical_report_page",
    "historical_heuristic",
    "historical_suggestion",
    "historical_n_records",
    "n_records_current",
    "historical_median",
    "current_median",
    "historical_iqr",
    "current_iqr",
    "historical_summary_stable",
    "deterministic_outcome",
    "suggested_action",
    "acceptance_eligibility",
    "historical_comparison"
  )

list_outputs <-
  base::list(
    pilot_candidate_evidence =
      list_evidence[["data_candidate_evidence"]],
    pilot_dataset_evidence =
      list_evidence[["data_dataset_evidence"]],
    pilot_record_evidence =
      list_evidence[["data_record_evidence"]],
    pilot_proposal_diagnostics =
      list_diagnosis[["data_proposal_diagnostics"]],
    pilot_candidate_recommendations =
      data_candidate_recommendations,
    pilot_historical_comparison =
      data_historical_comparison
  )

purrr::iwalk(
  list_outputs,
  function(data_output, output_name) {
    readr::write_csv(
      data_output,
      base::file.path(
        path_output_directory,
        stringr::str_c(output_name, ".csv")
      )
    )
  }
)

data_candidate_recommendations |>
  dplyr::count(
    .data[["trait_domain_name"]],
    .data[["deterministic_outcome"]],
    .data[["acceptance_eligibility"]]
  ) |>
  base::print(n = Inf)

base::message(
  "Wrote non-mutating pilot diagnostics to ",
  path_output_directory,
  "."
)

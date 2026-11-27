#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Sort the VegVault 2.0.0 trait review queue
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time runner of the VegVault 2.0.0 migration (Stage V, step V3e).
# Run once per review stage:
#   Rscript run_trait_review_vegvault_2_0_0_triage.R raw
#   Rscript run_trait_review_vegvault_2_0_0_triage.R classified
# It chains the existing review builders with a neutral historical scope
#   and without v1 adjudications or decisions: evidence packets,
#   diagnosis, policy outputs, programmatic triage and reconciliation, and
#   interim closure. select_trait_review_proposals() then gives every
#   candidate one proposal: the policy (`none`, or `exclude` of values
#   <= 0), else the closure (`none` for insufficient evidence, `exclude` of
#   non-positive values), else the human review queue. Scale proposals,
#   which come from submission thresholds in VegVault 1.0.0 units, only
#   ever reach the queue as suggestions.
# Nothing is approved here. The proposals are written to
#   Data/Temp/Trait_corrections/<stage>/vegvault_2_0_0_triage/, with a
#   report in Outputs/Reports/Trait_corrections/<stage>/. Approval runs in
#   run_trait_review_vegvault_2_0_0_approval.R.
# Inputs: the VegVault 2.0.0 trait store under Data/Temp (built up to the
#   stage's review queue) and, for the raw stage, the submission audit of
#   recover_trait_review_submission.R.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

review_stage <-
  base::commandArgs(trailingOnly = TRUE) |>
  base::c("raw") |>
  purrr::pluck(1L)

assertthat::assert_that(
  review_stage %in% base::c("raw", "classified"),
  msg = "The review stage must be 'raw' or 'classified'."
)

path_vegvault <-
  here::here("Data/Input/VegVault.sqlite")
path_store_v2 <-
  here::here(
    "Data/Temp/vegvault_2_migration/traits_reference_v2",
    "pipeline_traits_reference"
  )
dir_stage_temp <-
  here::here("Data/Temp/Trait_corrections", review_stage)
dir_triage <-
  base::file.path(dir_stage_temp, "vegvault_2_0_0_triage")
dir_report <-
  here::here("Outputs/Reports/Trait_corrections", review_stage)
path_report <-
  base::file.path(
    dir_report,
    "trait_review_vegvault_2_0_0_triage_report.md"
  )
path_proposals <-
  base::file.path(dir_triage, "trait_review_proposals.csv")
evidence_reference <-
  stringr::str_c(
    "Outputs/Reports/Trait_corrections/",
    review_stage,
    "/trait_review_vegvault_2_0_0_triage_report.md"
  )

base::dir.create(dir_triage, recursive = TRUE, showWarnings = FALSE)
base::dir.create(dir_report, recursive = TRUE, showWarnings = FALSE)


#----------------------------------------------------------#
# 1. Load inputs -----
#----------------------------------------------------------#

data_vegvault_release <-
  load_vegvault_database_version(
    path_to_vegvault = path_vegvault,
    vegvault_version = "2.0.0"
  )

assertthat::assert_that(
  base::identical(
    base::as.list(
      targets::tar_read_raw(
        name = "config_vegvault_release",
        store = path_store_v2
      )
    ),
    base::as.list(data_vegvault_release)
  ),
  msg = "The 2.0.0 trait store was built from another VegVault file."
)

dir_trait_corrections <-
  resolve_trait_correction_directory(
    vegvault_version = data_vegvault_release[["vegvault_version"]]
  )

data_trait_review_decisions <-
  load_trait_review_decisions(
    path_trait_review_decisions = base::file.path(
      dir_trait_corrections,
      stringr::str_c("trait_review_decisions_", review_stage, ".csv")
    )
  )

assertthat::assert_that(
  base::nrow(data_trait_review_decisions) == 0L,
  msg = stringr::str_c(
    "The triage starts from an empty 2.0.0 decision file; this stage ",
    "already has decisions."
  )
)

if (
  review_stage == "raw"
) {
  data_trait_records <-
    targets::tar_read_raw(
      name = "data_traits_source_scaled",
      store = path_store_v2
    )
  data_trait_review_candidates <-
    targets::tar_read_raw(
      name = "data_trait_review_candidates_raw",
      store = path_store_v2
    )
  data_submission_audit <-
    readr::read_csv(
      base::file.path(dir_stage_temp, "review_submission_audit.csv"),
      show_col_types = FALSE,
      progress = FALSE
    )
} else {
  data_trait_records <-
    targets::tar_read_raw(
      name = "data_traits_classified",
      store = path_store_v2
    ) |>
    dplyr::select(-"taxon_name") |>
    dplyr::rename(taxon_name = "taxon_resolved")
  data_trait_review_candidates <-
    targets::tar_read_raw(
      name = "data_trait_review_candidates_classified",
      store = path_store_v2
    )
  # The submission keys belong to the raw stage only
  data_submission_audit <-
    tibble::tibble(
      candidate_id = base::character(),
      action_source = base::character(),
      scale_factor_source = base::character(),
      notes_lower = base::character(),
      source_row = base::integer()
    )
}

assertthat::assert_that(
  base::all(
    data_submission_audit[["candidate_id"]] %in%
      data_trait_review_candidates[["candidate_id"]]
  ),
  msg = "The submission audit belongs to another candidate queue."
)


#----------------------------------------------------------#
# 2. Neutral history -----
#----------------------------------------------------------#

# VegVault 1.0.0 reviews do not carry over: no candidate is in the
#   historical scope, and no implicit no-action proposal is allowed
data_reconciliation <-
  data_trait_review_candidates |>
  dplyr::mutate(
    implicit_none_proposal_eligible = FALSE,
    historical_scope_status = "not_in_historical_scope"
  )

data_historical_scope <-
  data_trait_review_candidates |>
  dplyr::select("candidate_id") |>
  dplyr::mutate(
    historical_n_records = NA_integer_,
    historical_median = NA_real_,
    historical_iqr = NA_real_,
    historical_heuristic = NA_character_,
    historical_suggestion = NA_character_
  )

data_empty_adjudications <-
  tibble::tibble(
    candidate_id = base::character(),
    review_role = base::character(),
    recommendation = base::character(),
    evidence_reference = base::character()
  )


#----------------------------------------------------------#
# 3. Chain the review builders -----
#----------------------------------------------------------#

list_evidence <-
  build_trait_review_evidence_packets(
    data_trait_records = data_trait_records,
    data_trait_review_reconciliation = data_reconciliation,
    data_historical_review_scope = data_historical_scope
  )

list_diagnosis <-
  diagnose_trait_review_candidates(
    data_candidate_evidence = list_evidence[["data_candidate_evidence"]],
    data_record_evidence = list_evidence[["data_record_evidence"]],
    data_review_decision_proposals = data_trait_review_decisions
  )

list_policy <-
  build_trait_review_policy_outputs(
    data_candidate_recommendations =
      list_diagnosis[["data_candidate_recommendations"]],
    evidence_reference = evidence_reference
  )

list_triage <-
  build_trait_review_programmatic_triage(
    data_candidate_recommendations =
      list_diagnosis[["data_candidate_recommendations"]],
    data_approved_decisions = data_trait_review_decisions,
    data_proposal_diagnostics =
      list_diagnosis[["data_proposal_diagnostics"]],
    data_dataset_evidence = list_evidence[["data_dataset_evidence"]],
    data_record_evidence = list_evidence[["data_record_evidence"]],
    data_agent_adjudications = data_empty_adjudications,
    evidence_reference = evidence_reference,
    min_source_pattern_candidates = 3L,
    source_factor_relative_tolerance = 0.25,
    agent_groups_per_batch = 10L
  )

list_programmatic_reconciliation <-
  build_trait_review_programmatic_reconciliation(
    data_candidate_triage = list_triage[["data_candidate_triage"]],
    data_source_pairs = list_triage[["data_source_pairs"]],
    data_submission_audit = data_submission_audit,
    data_record_evidence = list_evidence[["data_record_evidence"]],
    evidence_reference = evidence_reference
  )

# The closure covers every candidate without a policy proposal. It returns
#   approved rows by design; select_trait_review_proposals() turns them
#   back into proposals, so the placeholder reviewer never reaches a
#   decision file
list_closure <-
  build_trait_review_interim_closure(
    data_trait_review_candidates = data_trait_review_candidates,
    data_trait_review_decisions =
      list_policy[["data_policy_proposals"]] |>
      dplyr::mutate(review_status = "approved"),
    data_candidate_triage = list_triage[["data_candidate_triage"]],
    data_candidate_reconciliation =
      list_programmatic_reconciliation[["data_candidate_reconciliation"]],
    reviewer = "vegvault_2_0_0_triage",
    reviewed_at = base::format(base::Sys.Date(), "%Y-%m-%d"),
    evidence_reference = evidence_reference
  )


#----------------------------------------------------------#
# 4. One proposal per candidate -----
#----------------------------------------------------------#

data_trait_review_proposals <-
  select_trait_review_proposals(
    data_trait_review_candidates = data_trait_review_candidates,
    data_policy_proposals = list_policy[["data_policy_proposals"]],
    data_closure_decisions = list_closure[["data_approved_decisions"]],
    data_queue_suggestions =
      list_programmatic_reconciliation[["data_decision_proposals"]]
  )

data_review_queue <-
  data_trait_review_proposals |>
  dplyr::filter(.data[["proposal_source"]] == "queue") |>
  dplyr::left_join(
    list_evidence[["data_candidate_evidence"]] |>
      dplyr::select(
        "candidate_id",
        dplyr::any_of(
          base::c(
            "n_records_current",
            "n_nonpositive",
            "possible_unit_pattern",
            "candidate_impact_score"
          )
        )
      ),
    by = dplyr::join_by(candidate_id),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    list_closure[["data_closure_audit"]] |>
      dplyr::select("candidate_id", "triage_outcome", "closure_outcome"),
    by = dplyr::join_by(candidate_id),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    list_programmatic_reconciliation[["data_candidate_reconciliation"]] |>
      dplyr::select("candidate_id", "reconciliation_outcome"),
    by = dplyr::join_by(candidate_id),
    relationship = "many-to-one"
  )


#----------------------------------------------------------#
# 5. Write proposals, audits and the report -----
#----------------------------------------------------------#

readr::write_csv(data_trait_review_proposals, path_proposals, na = "")
readr::write_csv(
  data_review_queue,
  base::file.path(dir_triage, "trait_review_queue.csv"),
  na = ""
)
# Template for the reviewer: the queue rows in the decision columns, to be
#   completed and saved as trait_review_manual_resolutions_<stage>.csv in
#   the release folder of the trait corrections
readr::write_csv(
  data_trait_review_proposals |>
    dplyr::filter(.data[["proposal_source"]] == "queue") |>
    dplyr::select(-"proposal_source", -"has_overridden_suggestion"),
  base::file.path(
    dir_triage,
    "trait_review_manual_resolutions_template.csv"
  ),
  na = ""
)
readr::write_csv(
  list_evidence[["data_candidate_evidence"]],
  base::file.path(dir_triage, "trait_review_candidate_evidence.csv"),
  na = ""
)
readr::write_csv(
  list_diagnosis[["data_candidate_recommendations"]],
  base::file.path(dir_triage, "trait_review_candidate_recommendations.csv"),
  na = ""
)
readr::write_csv(
  list_triage[["data_candidate_triage"]],
  base::file.path(dir_triage, "trait_review_candidate_triage.csv"),
  na = ""
)
readr::write_csv(
  list_programmatic_reconciliation[["data_candidate_reconciliation"]],
  base::file.path(dir_triage, "trait_review_candidate_reconciliation.csv"),
  na = ""
)
readr::write_csv(
  list_closure[["data_closure_audit"]],
  base::file.path(dir_triage, "trait_review_closure_audit.csv"),
  na = ""
)

sha256_proposals <-
  digest::digest(path_proposals, algo = "sha256", file = TRUE)

data_summary_source <-
  data_trait_review_proposals |>
  dplyr::distinct(
    .data[["candidate_id"]],
    .data[["proposal_source"]],
    .data[["action"]],
    .data[["trait_domain_name"]]
  ) |>
  dplyr::count(
    .data[["trait_domain_name"]],
    .data[["proposal_source"]],
    .data[["action"]],
    name = "n_candidates"
  )

n_candidates <- base::nrow(data_trait_review_candidates)
n_queue <-
  data_review_queue[["candidate_id"]] |>
  base::unique() |>
  base::length()
n_overridden <-
  base::sum(data_trait_review_proposals[["has_overridden_suggestion"]])

vec_report_lines <-
  base::c(
    stringr::str_glue(
      "# VegVault 2.0.0 trait review triage: {review_stage} stage"
    ),
    "",
    "## Status",
    "",
    stringr::str_glue(
      "Proposals only; nothing is approved. Built from VegVault ",
      "{data_vegvault_release[['vegvault_version']]} (manifest ",
      "`{data_vegvault_release[['manifest_sha256']]}`) on ",
      "{base::format(base::Sys.Date(), '%Y-%m-%d')}."
    ),
    "",
    stringr::str_glue(
      "{n_candidates} candidates: ",
      "{n_candidates - n_queue} with an automated proposal, ",
      "{n_queue} in the human review queue. ",
      "{n_overridden} automated proposals set aside a queue suggestion."
    ),
    "",
    stringr::str_glue(
      "Proposal file: `{base::basename(path_proposals)}` in ",
      "`Data/Temp/Trait_corrections/{review_stage}/vegvault_2_0_0_triage/`,",
      " SHA-256 `{sha256_proposals}`."
    ),
    "",
    "## Proposals by domain, source and action",
    "",
    data_summary_source |>
      knitr::kable(format = "pipe") |>
      base::as.character(),
    "",
    "## Rules",
    "",
    stringr::str_c(
      "Each candidate takes the first proposal available: the policy ",
      "(`none`, or `exclude` of values <= 0), the interim closure (`none` ",
      "for insufficient evidence, `exclude` of non-positive values), or ",
      "the human review queue. Scale proposals derived from the review ",
      "submission use VegVault 1.0.0 units and are never approved ",
      "automatically. No VegVault 1.0.0 decision or historical review is ",
      "used."
    )
  )
readr::write_lines(vec_report_lines, path_report)

base::print(data_summary_source, n = Inf)
cli::cli_inform(
  c(
    "v" = "{n_candidates} candidates, {n_queue} in the review queue.",
    "i" = "Proposals: {.path {path_proposals}}",
    "i" = "SHA-256: {sha256_proposals}"
  )
)

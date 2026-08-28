#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Record completed trait-investigation approvals
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This one-time provenance runner records the project owner's explicit
#   approval of no-action decisions after completed investigation.

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
path_none_proposals <-
  base::file.path(
    path_triage_directory,
    "trait_review_programmatic_none_proposals.csv"
  )
path_completed_adjudications <-
  base::file.path(
    path_triage_directory,
    "trait_review_programmatic_completed_adjudications.csv"
  )
path_decisions_raw <-
  here::here(
    "Data/Input/Trait_corrections/trait_review_decisions_raw.csv"
  )
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )

data_none_proposals <-
  load_trait_review_decisions(path_none_proposals)
data_completed_adjudications <-
  readr::read_csv(
    path_completed_adjudications,
    show_col_types = FALSE,
    progress = FALSE
  ) |>
  dplyr::filter(
    .data[["review_role"]] == "adjudicator",
    .data[["recommendation"]] %in%
      base::c("none", "insufficient_evidence")
  )
vec_all_completed_candidate_ids <-
  base::unique(data_completed_adjudications[["candidate_id"]])
data_existing_decisions <-
  load_trait_review_decisions(path_decisions_raw)
vec_existing_completed_candidate_ids <-
  base::intersect(
    vec_all_completed_candidate_ids,
    data_existing_decisions[["candidate_id"]]
  )
vec_new_completed_candidate_ids <-
  base::setdiff(
    vec_all_completed_candidate_ids,
    data_existing_decisions[["candidate_id"]]
  )

assertthat::assert_that(
  base::length(vec_all_completed_candidate_ids) == 54L,
  !base::anyDuplicated(vec_all_completed_candidate_ids),
  base::length(vec_existing_completed_candidate_ids) == 2L,
  base::length(vec_new_completed_candidate_ids) == 52L,
  base::all(
    data_existing_decisions[["action"]][
      base::match(
        vec_existing_completed_candidate_ids,
        data_existing_decisions[["candidate_id"]]
      )
    ] == "none"
  ),
  msg = "Completed investigations no longer match the approved snapshot."
)

data_completed_proposals <-
  data_none_proposals |>
  dplyr::filter(
    .data[["candidate_id"]] %in% vec_new_completed_candidate_ids
  )
assertthat::assert_that(
  base::nrow(data_completed_proposals) == 52L,
  base::all(data_completed_proposals[["action"]] == "none"),
  base::all(
    data_completed_proposals[["review_status"]] == "proposed"
  ),
  msg = "Completed no-action proposals no longer match the approval."
)

data_new_approved_decisions <-
  data_completed_proposals |>
  dplyr::mutate(
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-26"
  )
assertthat::assert_that(
  !base::any(
    data_new_approved_decisions[["candidate_id"]] %in%
      data_existing_decisions[["candidate_id"]]
  ),
  msg = "A completed investigation is already recorded canonically."
)
data_approved_decisions <-
  dplyr::bind_rows(
    data_existing_decisions,
    data_new_approved_decisions
  )
assertthat::assert_that(
  base::nrow(data_existing_decisions) == 2320L,
  base::nrow(data_approved_decisions) == 2372L,
  !base::anyDuplicated(data_approved_decisions[["decision_id"]]),
  !base::anyDuplicated(data_approved_decisions[["candidate_id"]]),
  msg = "Combined approvals do not match the expected decision set."
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

assertthat::assert_that(
  base::nrow(data_approved_candidates) == 2372L,
  base::sum(data_application_audit[["n_excluded"]]) == 15864L,
  base::sum(data_application_audit[["n_scaled"]]) == 0L,
  msg = "Combined approvals no longer reproduce the reviewed impact."
)

readr::write_csv(
  data_approved_decisions,
  path_decisions_raw,
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
  "Recorded 52 approved no-action decisions after completed ",
  "investigation; 1,928 raw candidates remain unresolved."
)

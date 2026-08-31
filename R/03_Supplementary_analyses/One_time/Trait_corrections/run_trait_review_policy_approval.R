#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Record trait-review policy approval
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This one-time provenance runner records the project owner's explicit
#   approval of the conservative policy proposals reviewed on 2026-08-26.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_policy_proposals <-
  here::here(
    "Data/Temp/Trait_corrections/raw/policy/",
    "trait_review_policy_proposals.csv"
  )
path_decisions_raw <-
  here::here(
    "Data/Input/Trait_corrections/trait_review_decisions_raw.csv"
  )
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )

data_policy_proposals <-
  load_trait_review_decisions(path_policy_proposals)
data_existing_decisions <-
  load_trait_review_decisions(path_decisions_raw)

assertthat::assert_that(
  base::nrow(data_existing_decisions) == 0L ||
    base::identical(
      data_existing_decisions[["decision_id"]],
      data_policy_proposals[["decision_id"]]
    ),
  msg = "Canonical raw decisions contain a different decision set."
)
assertthat::assert_that(
  base::nrow(data_policy_proposals) == 2320L,
  base::sum(data_policy_proposals[["action"]] == "none") == 2301L,
  base::sum(data_policy_proposals[["action"]] == "exclude") == 19L,
  base::all(data_policy_proposals[["review_status"]] == "proposed"),
  msg = "Policy proposals no longer match the approved review snapshot."
)

data_exclusion_proposals <-
  data_policy_proposals |>
  dplyr::filter(.data[["action"]] == "exclude")
assertthat::assert_that(
  base::all(base::is.na(data_exclusion_proposals[["value_lower"]])),
  base::all(data_exclusion_proposals[["value_upper"]] == 0),
  base::all(data_exclusion_proposals[["value_upper_inclusive"]]),
  msg = "Approved exclusions must retain the reviewed non-positive selector."
)

data_approved_decisions <-
  data_policy_proposals |>
  dplyr::mutate(
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-26"
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
    data_trait_review_decisions = data_approved_decisions_validated
  )
data_application_audit <-
  list_application[["data_correction_audit"]]

assertthat::assert_that(
  base::sum(data_application_audit[["n_excluded"]]) == 15864L,
  base::sum(data_application_audit[["n_scaled"]]) == 0L,
  base::nrow(data_trait_review_candidates) == 4300L,
  base::nrow(data_approved_candidates) == 2320L,
  msg = "Approved decisions no longer reproduce the reviewed impact."
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
  msg = "Written raw decision values differ from the validated approval set."
)

base::message(
  "Recorded 2,301 approved no-action decisions and 19 approved ",
  "exclusions; 1,980 raw candidates remain pending structured review."
)

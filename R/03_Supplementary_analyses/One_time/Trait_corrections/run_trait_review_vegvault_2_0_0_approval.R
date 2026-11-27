#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Approve the VegVault 2.0.0 trait review decisions
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time runner of the VegVault 2.0.0 migration (Stage V, step V3e).
# Run once per review stage, after run_trait_review_vegvault_2_0_0_triage.R:
#   Rscript run_trait_review_vegvault_2_0_0_approval.R raw
#   Rscript run_trait_review_vegvault_2_0_0_approval.R classified
# The reviewer approves a stage by recording, in section 0 below, the
#   SHA-256 of the proposal file they reviewed, their name and the review
#   date. Their resolutions are rows in the decision columns in
#   trait_review_manual_resolutions_<stage>.csv of the release folder:
#   every queue candidate needs at least one row, and a row for any other
#   candidate replaces its automated proposal. An empty decision_id is
#   computed from the row's selector.
# The runner merges the automated proposals with the resolutions, runs
#   validate_trait_review_decisions(), simulates
#   apply_trait_review_decisions(), and only then writes
#   trait_review_decisions_<stage>.csv into the release folder. It stops
#   when the proposal file changed after the review, when the stage already
#   has decisions, or when a queue candidate is unresolved.


#----------------------------------------------------------#
# 0. Setup and approval record -----
#----------------------------------------------------------#

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

# Filled by the reviewer when approving a stage
list_approval_records <-
  base::list(
    raw = base::list(
      proposals_sha256 = NA_character_,
      reviewer = NA_character_,
      reviewed_at = NA_character_
    ),
    classified = base::list(
      proposals_sha256 = NA_character_,
      reviewer = NA_character_,
      reviewed_at = NA_character_
    )
  )

review_stage <-
  base::commandArgs(trailingOnly = TRUE) |>
  base::c("raw") |>
  purrr::pluck(1L)

assertthat::assert_that(
  review_stage %in% base::c("raw", "classified"),
  msg = "The review stage must be 'raw' or 'classified'."
)

list_approval <- list_approval_records[[review_stage]]

path_vegvault <-
  here::here("Data/Input/VegVault.sqlite")
path_store_v2 <-
  here::here(
    "Data/Temp/vegvault_2_migration/traits_reference_v2",
    "pipeline_traits_reference"
  )
path_proposals <-
  here::here(
    "Data/Temp/Trait_corrections",
    review_stage,
    "vegvault_2_0_0_triage/trait_review_proposals.csv"
  )
dir_report <-
  here::here("Outputs/Reports/Trait_corrections", review_stage)
evidence_reference_triage <-
  stringr::str_c(
    "Outputs/Reports/Trait_corrections/",
    review_stage,
    "/trait_review_vegvault_2_0_0_triage_report.md"
  )


#----------------------------------------------------------#
# 1. Check the approval record and the reviewed file -----
#----------------------------------------------------------#

sha256_proposals <-
  digest::digest(path_proposals, algo = "sha256", file = TRUE)

if (
  base::is.na(list_approval[["proposals_sha256"]])
) {
  cli::cli_abort(
    c(
      "The {review_stage} stage has no approval record yet.",
      "i" = stringr::str_c(
        "Record the SHA-256 of the reviewed proposal file, the reviewer ",
        "and the review date in section 0 of this runner."
      ),
      "i" = "Current SHA-256: {sha256_proposals}"
    )
  )
}

assertthat::assert_that(
  base::identical(sha256_proposals, list_approval[["proposals_sha256"]]),
  msg = "The proposal file changed after it was reviewed."
)
assertthat::assert_that(
  base::is.character(list_approval[["reviewer"]]),
  base::nzchar(list_approval[["reviewer"]]),
  stringr::str_detect(
    list_approval[["reviewed_at"]],
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
  ),
  !base::is.na(
    base::as.Date(list_approval[["reviewed_at"]], format = "%Y-%m-%d")
  ),
  msg = "The approval record needs a reviewer and an ISO review date."
)


#----------------------------------------------------------#
# 2. Load inputs -----
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
path_decisions <-
  base::file.path(
    dir_trait_corrections,
    stringr::str_c("trait_review_decisions_", review_stage, ".csv")
  )
path_resolutions <-
  base::file.path(
    dir_trait_corrections,
    stringr::str_c("trait_review_manual_resolutions_", review_stage, ".csv")
  )

assertthat::assert_that(
  base::nrow(load_trait_review_decisions(path_decisions)) == 0L,
  msg = "This stage already has 2.0.0 decisions; nothing is overwritten."
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
  data_source_scale_record_audit <-
    targets::tar_read_raw(
      name = "data_trait_source_scale_record_audit",
      store = path_store_v2
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
  data_source_scale_record_audit <- NULL
}

data_proposals <-
  readr::read_csv(
    path_proposals,
    col_types = readr::cols(
      dataset_id = readr::col_integer(),
      value_lower = readr::col_double(),
      value_lower_inclusive = readr::col_logical(),
      value_upper = readr::col_double(),
      value_upper_inclusive = readr::col_logical(),
      scale_factor = readr::col_double(),
      has_overridden_suggestion = readr::col_logical(),
      .default = readr::col_character()
    ),
    na = "",
    progress = FALSE
  )

assertthat::assert_that(
  base::setequal(
    data_proposals[["candidate_id"]],
    data_trait_review_candidates[["candidate_id"]]
  ),
  msg = "The proposals belong to another candidate queue; rerun the triage."
)

data_resolutions <-
  load_trait_review_decisions(
    path_trait_review_decisions = path_resolutions
  )


#----------------------------------------------------------#
# 3. Merge proposals and resolutions -----
#----------------------------------------------------------#

vec_queue_ids <-
  data_proposals |>
  dplyr::filter(.data[["proposal_source"]] == "queue") |>
  dplyr::pull("candidate_id") |>
  base::unique()

vec_unresolved_ids <-
  base::setdiff(vec_queue_ids, data_resolutions[["candidate_id"]])

if (
  base::length(vec_unresolved_ids) > 0L
) {
  cli::cli_abort(
    c(
      "Every queue candidate needs a resolution.",
      "x" = "{base::length(vec_unresolved_ids)} candidate{?s} unresolved.",
      "i" = "Add rows to {.path {path_resolutions}}."
    )
  )
}

assertthat::assert_that(
  base::all(data_resolutions[["review_status"]] == "approved"),
  msg = "Every resolution row must have review_status 'approved'."
)

data_resolutions_completed <-
  data_resolutions |>
  dplyr::mutate(
    reviewer = dplyr::coalesce(
      .data[["reviewer"]],
      list_approval[["reviewer"]]
    ),
    reviewed_at = dplyr::coalesce(
      .data[["reviewed_at"]],
      list_approval[["reviewed_at"]]
    ),
    evidence_reference = dplyr::coalesce(
      .data[["evidence_reference"]],
      evidence_reference_triage
    ),
    source_reference = dplyr::coalesce(
      .data[["source_reference"]],
      stringr::str_c("manual_resolution:", review_stage)
    ),
    # paste() writes missing selector parts as "NA", so every row keeps a
    #   distinct key
    decision_key = base::paste(
      .data[["candidate_id"]],
      .data[["action"]],
      .data[["trait_name"]],
      .data[["dataset_id"]],
      .data[["value_lower"]],
      .data[["value_lower_inclusive"]],
      .data[["value_upper"]],
      .data[["value_upper_inclusive"]],
      .data[["scale_factor"]],
      "manual_resolution_vegvault_2_0_0",
      sep = "|"
    ),
    decision_id = dplyr::coalesce(
      .data[["decision_id"]],
      purrr::map_chr(
        .data[["decision_key"]],
        ~ digest::digest(.x, algo = "sha256", serialize = FALSE)
      )
    )
  ) |>
  dplyr::select(-"decision_key")

data_automated_approved <-
  data_proposals |>
  dplyr::filter(
    .data[["proposal_source"]] %in% base::c("policy", "closure"),
    !.data[["candidate_id"]] %in% data_resolutions[["candidate_id"]]
  ) |>
  dplyr::select(-"proposal_source", -"has_overridden_suggestion") |>
  dplyr::mutate(
    review_status = "approved",
    reviewer = list_approval[["reviewer"]],
    reviewed_at = list_approval[["reviewed_at"]]
  )

data_trait_review_decisions <-
  dplyr::bind_rows(
    data_automated_approved,
    data_resolutions_completed
  ) |>
  dplyr::select(dplyr::all_of(base::names(data_resolutions)))


#----------------------------------------------------------#
# 4. Validate, simulate, and write -----
#----------------------------------------------------------#

data_trait_review_decisions_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_trait_review_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_trait_review_candidates,
    data_trait_source_scale_record_audit = data_source_scale_record_audit
  )

list_application <-
  apply_trait_review_decisions(
    data_trait_records = data_trait_records,
    data_trait_review_decisions = data_trait_review_decisions_validated,
    data_trait_source_scale_record_audit = data_source_scale_record_audit
  )

readr::write_csv(
  data_trait_review_decisions_validated,
  path_decisions,
  na = ""
)

data_decisions_reloaded <-
  load_trait_review_decisions(path_trait_review_decisions = path_decisions)

assertthat::assert_that(
  base::nrow(data_decisions_reloaded) ==
    base::nrow(data_trait_review_decisions_validated),
  base::identical(
    data_decisions_reloaded[["decision_id"]],
    data_trait_review_decisions_validated[["decision_id"]]
  ),
  msg = "The written decision file does not read back unchanged."
)

data_decisions_revalidated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_decisions_reloaded,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_trait_review_candidates,
    data_trait_source_scale_record_audit = data_source_scale_record_audit
  )

data_application_audit <-
  list_application[["data_correction_audit"]]

readr::write_csv(
  data_application_audit,
  base::file.path(
    dir_report,
    "trait_review_vegvault_2_0_0_application_audit.csv"
  ),
  na = ""
)

data_trait_review_decisions_validated |>
  dplyr::count(.data[["trait_domain_name"]], .data[["action"]]) |>
  base::print(n = Inf)

cli::cli_inform(
  c(
    "v" = stringr::str_c(
      "{base::nrow(data_decisions_reloaded)} approved decisions written ",
      "for the {review_stage} stage."
    ),
    "i" = "{.path {path_decisions}}",
    "i" = stringr::str_c(
      "Simulated application: ",
      "{base::sum(data_application_audit[['n_excluded']])} records ",
      "excluded, {base::sum(data_application_audit[['n_scaled']])} scaled."
    )
  )
)

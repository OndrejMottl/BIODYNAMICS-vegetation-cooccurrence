#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Run grouped trait-review investigation
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This runner records conservative no-action decisions and closes candidates
#   covered by the source rules approved by the project owner.

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_report_directory <-
  here::here("Outputs/Reports/Trait_corrections/raw")
path_decisions_raw <-
  here::here(
    "Data/Input/Trait_corrections/trait_review_decisions_raw.csv"
  )
path_exceptions <-
  base::file.path(
    path_report_directory,
    "trait_review_interim_closure_exceptions.csv"
  )
path_investigation_audit <-
  base::file.path(
    path_report_directory,
    "trait_review_grouped_investigation_audit.csv"
  )
path_pending_candidates <-
  base::file.path(
    path_report_directory,
    "trait_review_grouped_investigation_pending.csv"
  )
path_source_proposals <-
  base::file.path(
    path_report_directory,
    "trait_review_grouped_source_scale_proposals.csv"
  )
path_source_evidence <-
  base::file.path(
    path_report_directory,
    "trait_review_grouped_source_evidence.csv"
  )
path_follow_up_source_proposals <-
  base::file.path(
    path_report_directory,
    "trait_review_post_source_scale_proposals.csv"
  )
path_report <-
  base::file.path(
    path_report_directory,
    "trait_review_grouped_investigation_report.md"
  )
path_pending_decisions <-
  here::here(
    "Data/Temp/Trait_corrections/raw/",
    "trait_review_decisions_grouped_investigation_validated.csv"
  )
evidence_reference <-
  paste0(
    "Outputs/Reports/Trait_corrections/raw/",
    "trait_review_grouped_investigation_report.md"
  )
path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = "pipeline_traits_reference.R"
  )

base::dir.create(
  path_report_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

data_trait_records <-
  targets::tar_read_raw(
    name = "data_traits_source_scaled",
    store = path_trait_store
  )
data_trait_records_raw <-
  targets::tar_read_raw(
    name = "data_traits_raw",
    store = path_trait_store
  )
data_trait_review_candidates <-
  targets::tar_read_raw(
    name = "data_trait_review_candidates_raw",
    store = path_trait_store
  )
data_source_scale_audit <-
  targets::tar_read_raw(
    name = "data_trait_source_scale_record_audit",
    store = path_trait_store
  )
data_exceptions <-
  readr::read_csv(
    path_exceptions,
    show_col_types = FALSE,
    progress = FALSE
  )
data_canonical_decisions <-
  load_trait_review_decisions(path_decisions_raw)
superseded_decision_id <-
  "7151e62842ecd3ef13893ae8337b420839a49131525ce9290fac1456e42ffa58"
data_superseded_taxon_scale <-
  data_canonical_decisions |>
  dplyr::filter(.data[["decision_id"]] == superseded_decision_id)
supersession_reference <-
  stringr::str_c(
    "source_scale_supersession:",
    superseded_decision_id
  )
data_superseded_existing <-
  data_canonical_decisions |>
  dplyr::filter(
    .data[["source_reference"]] == supersession_reference
  )
assertthat::assert_that(
  base::nrow(data_superseded_taxon_scale) +
    base::nrow(data_superseded_existing) == 1L,
  msg = "The source-superseded taxon rule changed unexpectedly."
)
if (
  base::nrow(data_superseded_taxon_scale) == 1L
) {
  assertthat::assert_that(
    data_superseded_taxon_scale[["action"]][[1L]] == "scale",
    data_superseded_taxon_scale[["scale_factor"]][[1L]] == 0.01,
    msg = "The original source-superseded taxon rule changed."
  )
  data_superseded_none <-
    data_superseded_taxon_scale |>
    dplyr::mutate(
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = NA_real_,
      value_upper_inclusive = NA,
      action = "none",
      scale_factor = NA_real_,
      rationale = stringr::str_c(
        "The earlier x0.01 threshold interpretation is superseded by the ",
        "approved source-155 x100 correction; no residual taxon-specific ",
        "correction is required."
      ),
      decision_key = stringr::str_c(
        .data[["candidate_id"]],
        "none",
        "source_scale_supersession_v1",
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
      evidence_reference = evidence_reference,
      source_reference = supersession_reference,
      review_status = "approved",
      reviewer = "OndrejMottl",
      reviewed_at = "2026-08-30"
    ) |>
    dplyr::select(base::names(data_canonical_decisions))
} else {
  data_superseded_none <- data_superseded_existing
}
superseded_betula_decision_id <-
  "965da49dbde123752d0f4ceb3289ec12acffa4ea1f49e888b5d107810aff390f"
data_superseded_betula_scale <-
  data_canonical_decisions |>
  dplyr::filter(
    .data[["decision_id"]] == superseded_betula_decision_id
  )
betula_supersession_reference <-
  stringr::str_c(
    "source_scale_supersession:",
    superseded_betula_decision_id
  )
data_superseded_betula_existing <-
  data_canonical_decisions |>
  dplyr::filter(
    .data[["source_reference"]] == betula_supersession_reference
  )
assertthat::assert_that(
  base::nrow(data_superseded_betula_scale) +
    base::nrow(data_superseded_betula_existing) == 1L,
  msg = "The Betula source-superseded rule changed unexpectedly."
)
if (
  base::nrow(data_superseded_betula_scale) == 1L
) {
  assertthat::assert_that(
    data_superseded_betula_scale[["action"]][[1L]] == "scale",
    data_superseded_betula_scale[["scale_factor"]][[1L]] == 0.1,
    msg = "The original Betula source-superseded rule changed."
  )
  data_superseded_betula_none <-
    data_superseded_betula_scale |>
    dplyr::mutate(
      trait_name = NA_character_,
      dataset_id = NA_integer_,
      value_lower = NA_real_,
      value_lower_inclusive = NA,
      value_upper = NA_real_,
      value_upper_inclusive = NA,
      action = "none",
      scale_factor = NA_real_,
      rationale = stringr::str_c(
        "The earlier x0.1 threshold interpretation is superseded by ",
        "the approved source-352 x100 correction; no residual ",
        "Betula papyrifera correction is required."
      ),
      decision_key = stringr::str_c(
        .data[["candidate_id"]],
        "none",
        "source_scale_supersession_v1",
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
      evidence_reference = evidence_reference,
      source_reference = betula_supersession_reference,
      review_status = "approved",
      reviewer = "OndrejMottl",
      reviewed_at = "2026-08-31"
    ) |>
    dplyr::select(base::names(data_canonical_decisions))
} else {
  data_superseded_betula_none <-
    data_superseded_betula_existing
}
data_existing_decisions <-
  data_canonical_decisions |>
  dplyr::filter(
    .data[["decision_id"]] != superseded_decision_id,
    .data[["decision_id"]] != superseded_betula_decision_id,
    .data[["source_reference"]] != supersession_reference,
    .data[["source_reference"]] != betula_supersession_reference,
    !stringr::str_starts(
      .data[["source_reference"]],
      "grouped_investigation:"
    )
  )

data_source_proposal_contract <-
  tibble::tribble(
    ~data_source_id,
    ~expected_data_source_desc,
    ~trait_domain_name,
    ~scale_factor,
    ~rationale,
    155L,
    "Tundra Trait Team",
    "Plant heigh",
    100,
    paste0(
      "Source values are in metres while the working Plant heigh scale ",
      "is centimetres; grouped cross-source evidence supports x100."
    ),
    243L,
    "Niwot Alpine Plant Traits",
    "Leaf Area",
    100,
    paste0(
      "Source leaf-area values are consistent with square centimetres ",
      "while the working Leaf Area scale is square millimetres."
    )
  ) |>
  dplyr::mutate(
    vegvault_version = "1.0.0",
    trait_name = NA_character_,
    evidence_reference = evidence_reference,
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-30"
  )
data_source_match_counts <-
  data_trait_records |>
  dplyr::inner_join(
    data_source_proposal_contract |>
      dplyr::select(
        "data_source_id",
        "trait_domain_name"
      ),
    by = dplyr::join_by(data_source_id, trait_domain_name),
    relationship = "many-to-one"
  ) |>
  dplyr::count(
    .data[["data_source_id"]],
    .data[["trait_domain_name"]],
    name = "expected_match_count"
  )
data_source_proposals <-
  data_source_proposal_contract |>
  dplyr::left_join(
    data_source_match_counts,
    by = dplyr::join_by(data_source_id, trait_domain_name),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    rule_key = stringr::str_c(
      .data[["vegvault_version"]],
      .data[["data_source_id"]],
      .data[["trait_domain_name"]],
      "",
      .data[["scale_factor"]],
      sep = "|"
    ),
    source_scale_rule_id = purrr::map_chr(
      .data[["rule_key"]],
      ~ digest::digest(
        .x,
        algo = "sha256",
        serialize = FALSE
      )
    )
  ) |>
  dplyr::select(
    "source_scale_rule_id",
    "vegvault_version",
    "data_source_id",
    "expected_data_source_desc",
    "trait_domain_name",
    "trait_name",
    "scale_factor",
    "expected_match_count",
    "rationale",
    "evidence_reference",
    "review_status",
    "reviewer",
    "reviewed_at"
  )
data_source_proposals_validated <-
  validate_trait_source_scale_rules(
    data_trait_source_scale_rules = data_source_proposals,
    data_trait_records = data_trait_records_raw,
    path_vegvault = here::here("Data/Input/VegVault.sqlite")
  )

data_source_taxon_medians <-
  data_trait_records |>
  dplyr::filter(
    base::is.finite(.data[["trait_value"]]),
    .data[["trait_value"]] > 0
  ) |>
  dplyr::inner_join(
    data_source_proposals |>
      dplyr::select(
        source_id_focus = "data_source_id",
        "trait_domain_name",
        "scale_factor"
      ),
    by = dplyr::join_by(trait_domain_name),
    relationship = "many-to-many"
  ) |>
  dplyr::group_by(
    .data[["source_id_focus"]],
    .data[["trait_domain_name"]],
    .data[["scale_factor"]],
    .data[["taxon_name"]]
  ) |>
  dplyr::summarise(
    source_median = stats::median(
      .data[["trait_value"]][
        .data[["data_source_id"]] == .data[["source_id_focus"]]
      ]
    ),
    other_median = stats::median(
      .data[["trait_value"]][
        .data[["data_source_id"]] != .data[["source_id_focus"]]
      ]
    ),
    .groups = "drop"
  ) |>
  dplyr::filter(
    base::is.finite(.data[["source_median"]]),
    base::is.finite(.data[["other_median"]])
  ) |>
  dplyr::mutate(
    correction_ratio =
      .data[["other_median"]] / .data[["source_median"]],
    factor_relative_error = base::abs(
      .data[["correction_ratio"]] - .data[["scale_factor"]]
    ) / .data[["scale_factor"]]
  )
data_source_evidence <-
  data_source_taxon_medians |>
  dplyr::group_by(
    data_source_id = .data[["source_id_focus"]],
    .data[["trait_domain_name"]],
    .data[["scale_factor"]]
  ) |>
  dplyr::summarise(
    n_shared_taxa = dplyr::n(),
    correction_ratio_lwr_25 = stats::quantile(
      .data[["correction_ratio"]],
      0.25
    ),
    correction_ratio_median = stats::median(
      .data[["correction_ratio"]]
    ),
    correction_ratio_upr_75 = stats::quantile(
      .data[["correction_ratio"]],
      0.75
    ),
    fraction_within_25_percent = base::mean(
      .data[["factor_relative_error"]] <= 0.25
    ),
    .groups = "drop"
  )

data_candidate_source_memberships <-
  data_exceptions |>
  dplyr::select(
    "candidate_id",
    "taxon_name",
    "trait_domain_name"
  ) |>
  dplyr::inner_join(
    data_trait_records |>
      dplyr::distinct(
        .data[["taxon_name"]],
        .data[["trait_domain_name"]],
        .data[["data_source_id"]]
      ),
    by = dplyr::join_by(taxon_name, trait_domain_name),
    relationship = "many-to-many"
  ) |>
  dplyr::semi_join(
    data_source_proposals,
    by = dplyr::join_by(data_source_id, trait_domain_name)
  ) |>
  dplyr::select(
    "candidate_id",
    "trait_domain_name",
    "data_source_id"
  ) |>
  dplyr::distinct()

list_investigation <-
  build_trait_review_grouped_investigation(
    data_trait_review_exceptions = data_exceptions,
    data_candidate_source_memberships =
      data_candidate_source_memberships,
    data_source_scale_proposals = data_source_proposals_validated,
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-30",
    evidence_reference = evidence_reference
  )
data_investigation_audit <-
  list_investigation[["data_investigation_audit"]]
data_new_decisions <-
  list_investigation[["data_approved_decisions"]]
data_new_decisions_current <-
  data_new_decisions |>
  dplyr::semi_join(
    data_trait_review_candidates,
    by = dplyr::join_by(candidate_id)
  )
data_combined_decisions_initial <-
  dplyr::bind_rows(
    data_existing_decisions,
    data_superseded_none,
    data_superseded_betula_none,
    data_new_decisions_current
  )
data_post_source_candidates <-
  data_trait_review_candidates |>
  dplyr::anti_join(
    data_combined_decisions_initial,
    by = dplyr::join_by(candidate_id)
  )
data_follow_up_source_proposals <-
  tibble::tribble(
    ~data_source_id,
    ~expected_data_source_desc,
    ~expected_match_count,
    187L,
    "Abisko & Sheffield Database",
    248L,
    457L,
    paste0(
      "Alpine tundra plants - effects of climate warming on traits of ",
      "species in mid-latitude snowbeds"
    ),
    127L
  ) |>
  dplyr::mutate(
    vegvault_version = "1.0.0",
    trait_domain_name = "Plant heigh",
    trait_name = NA_character_,
    scale_factor = 100,
    rationale = stringr::str_c(
      "Source values are metre-scaled Plant height observations; ",
      "post-source-scaling evidence supports conversion to centimetres."
    ),
    evidence_reference = evidence_reference,
    review_status = "approved",
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-30",
    rule_key = stringr::str_c(
      .data[["vegvault_version"]],
      .data[["data_source_id"]],
      .data[["trait_domain_name"]],
      "",
      .data[["scale_factor"]],
      sep = "|"
    ),
    source_scale_rule_id = purrr::map_chr(
      .data[["rule_key"]],
      ~ digest::digest(
        .x,
        algo = "sha256",
        serialize = FALSE
      )
    )
  ) |>
  dplyr::select(
    "source_scale_rule_id",
    "vegvault_version",
    "data_source_id",
    "expected_data_source_desc",
    "trait_domain_name",
    "trait_name",
    "scale_factor",
    "expected_match_count",
    "rationale",
    "evidence_reference",
    "review_status",
    "reviewer",
    "reviewed_at"
  ) |>
  validate_trait_source_scale_rules(
    data_trait_records = data_trait_records_raw,
    path_vegvault = here::here("Data/Input/VegVault.sqlite")
  )
data_follow_up_memberships <-
  data_post_source_candidates |>
  dplyr::select(
    "candidate_id",
    "taxon_name",
    "trait_domain_name"
  ) |>
  dplyr::inner_join(
    data_trait_records |>
      dplyr::distinct(
        .data[["taxon_name"]],
        .data[["trait_domain_name"]],
        .data[["data_source_id"]]
      ),
    by = dplyr::join_by(taxon_name, trait_domain_name),
    relationship = "many-to-many"
  ) |>
  dplyr::semi_join(
    data_follow_up_source_proposals,
    by = dplyr::join_by(data_source_id, trait_domain_name)
  ) |>
  dplyr::select(
    "candidate_id",
    "trait_domain_name",
    "data_source_id"
  ) |>
  dplyr::distinct()
list_follow_up_investigation <-
  build_trait_review_grouped_investigation(
    data_trait_review_exceptions = data_post_source_candidates,
    data_candidate_source_memberships = data_follow_up_memberships,
    data_source_scale_proposals = data_follow_up_source_proposals,
    reviewer = "OndrejMottl",
    reviewed_at = "2026-08-30",
    evidence_reference = evidence_reference
  )
data_follow_up_decisions <-
  list_follow_up_investigation[["data_approved_decisions"]]
data_pending_candidates <-
  list_follow_up_investigation[["data_pending_candidates"]]
data_combined_decisions <-
  dplyr::bind_rows(
    data_combined_decisions_initial,
    data_follow_up_decisions
  )
data_covered_candidates <-
  data_trait_review_candidates |>
  dplyr::filter(
    .data[["candidate_id"]] %in%
      data_combined_decisions[["candidate_id"]]
  )
data_investigation_audit <-
  data_investigation_audit |>
  dplyr::mutate(
    investigation_outcome = dplyr::if_else(
      .data[["investigation_outcome"]] ==
        "approve_none_after_source_rule" &
        !.data[["candidate_id"]] %in%
          data_trait_review_candidates[["candidate_id"]],
      "resolved_by_source_rule_candidate_retired",
      .data[["investigation_outcome"]]
    )
  ) |>
  dplyr::bind_rows(
    list_follow_up_investigation[["data_investigation_audit"]]
  )

assertthat::assert_that(
  base::nrow(data_exceptions) == 392L,
  base::nrow(data_existing_decisions) == 3911L,
  base::nrow(data_superseded_none) == 1L,
  base::nrow(data_superseded_betula_none) == 1L,
  base::nrow(data_source_proposals) == 2L,
  base::identical(
    base::sort(data_source_proposals[["expected_match_count"]]),
    base::c(111L, 19715L)
  ),
  base::nrow(data_new_decisions) == 392L,
  base::nrow(data_new_decisions_current) == 386L,
  base::nrow(data_post_source_candidates) == 40L,
  base::nrow(data_follow_up_decisions) == 40L,
  base::nrow(data_pending_candidates) == 0L,
  base::nrow(data_combined_decisions) == 4339L,
  base::nrow(data_covered_candidates) == 4339L,
  base::nrow(data_trait_review_candidates) == 4339L,
  !base::anyDuplicated(data_combined_decisions[["decision_id"]]),
  !base::anyDuplicated(data_combined_decisions[["candidate_id"]]),
  msg = "Grouped investigation no longer matches its reviewed snapshot."
)

data_combined_decisions_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_combined_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_covered_candidates,
    data_trait_source_scale_record_audit =
      data_source_scale_audit
  )
readr::write_csv(
  data_combined_decisions_validated,
  path_pending_decisions,
  na = ""
)
data_serialized_decisions <-
  load_trait_review_decisions(path_pending_decisions)
data_serialized_validated <-
  validate_trait_review_decisions(
    data_trait_review_decisions = data_serialized_decisions,
    data_trait_records = data_trait_records,
    data_trait_review_candidates = data_covered_candidates,
    data_trait_source_scale_record_audit =
      data_source_scale_audit
  )
assertthat::assert_that(
  base::isTRUE(
    base::all.equal(
      base::as.data.frame(data_serialized_validated),
      base::as.data.frame(data_combined_decisions_validated),
      check.attributes = FALSE
    )
  ),
  msg = "Serialized grouped decisions differ from validated decisions."
)

data_summary <-
  data_investigation_audit |>
  dplyr::count(
    .data[["trait_domain_name"]],
    .data[["investigation_outcome"]],
    name = "n_candidates"
  ) |>
  dplyr::arrange(
    .data[["trait_domain_name"]],
    .data[["investigation_outcome"]]
  )
vec_summary_rows <-
  data_summary |>
  dplyr::transmute(
    report_row = stringr::str_c(
      "| ",
      .data[["trait_domain_name"]],
      " | ",
      .data[["investigation_outcome"]],
      " | ",
      .data[["n_candidates"]],
      " |"
    )
  ) |>
  dplyr::pull("report_row")
data_source_report <-
  data_source_proposals |>
  dplyr::left_join(
    data_source_evidence,
    by = dplyr::join_by(
      data_source_id,
      trait_domain_name,
      scale_factor
    ),
    relationship = "one-to-one"
  )
vec_source_rows <-
  data_source_report |>
  dplyr::transmute(
    report_row = stringr::str_c(
      "| ",
      .data[["data_source_id"]],
      " | ",
      .data[["expected_data_source_desc"]],
      " | ",
      .data[["trait_domain_name"]],
      " | x",
      .data[["scale_factor"]],
      " | ",
      .data[["expected_match_count"]],
      " | ",
      base::round(.data[["correction_ratio_median"]], 2L),
      " | ",
      base::round(
        100 * .data[["fraction_within_25_percent"]],
        1L
      ),
      "% |"
    )
  ) |>
  dplyr::pull("report_row")
vec_report <-
  base::c(
    "# Grouped trait-review investigation",
    "",
    "## Outcome",
    "",
    stringr::str_c(
      "The 392 interim exceptions were investigated as grouped source ",
      "and unit-factor patterns. Of these, 357 lack reproducible ",
      "source-level support and are now approved as explicit no-action ",
      "decisions under the project owner's conservative closure policy."
    ),
    "",
    stringr::str_c(
      "The remaining 35 historical candidates contain records from two ",
      "sources with credible whole-source unit hypotheses. The project ",
      "owner approved both rules on 2026-08-30. Of those candidates, 29 ",
      "remain in the queue with explicit residual no-action decisions and ",
      "six are no longer generated after source scaling."
    ),
    "",
    stringr::str_c(
      "Rebuilding the queue exposed nine new within-taxon outlier groups. ",
      "Six lack reproducible source-level evidence and resolve to none ",
      "under the conservative policy. The project owner approved the two ",
      "newly exposed metre-scaled source rules on 2026-08-30. Two affected ",
      "candidates retired and Phyteuma hemisphaericum receives an explicit ",
      "residual no-action decision after source scaling."
    ),
    "",
    stringr::str_c(
      "Classified-stage investigation subsequently identified four more ",
      "source-wide unit corrections, approved on 2026-08-31. Rebuilding ",
      "the raw queue exposed 33 additional outlier groups. None contains ",
      "invalid values or a repeated source-factor pattern, so all 33 ",
      "resolve to no action under the conservative policy."
    ),
    "",
    "| Trait domain | Investigation outcome | Candidates |",
    "|---|---|---:|",
    vec_summary_rows,
    "",
    "## Approved source rules",
    "",
    paste0(
      "| Source ID | Source | Trait domain | Factor | Records | ",
      "Median cross-source ratio | Shared taxa within 25% |"
    ),
    "|---:|---|---|---:|---:|---:|---:|",
    vec_source_rows,
    "",
    stringr::str_c(
      "Source 155 (Tundra Trait Team) contains Plant heigh values with ",
      "median 0.075 and range 0 to 2.8, consistent with metres. Across ",
      "213 taxa shared with independent sources, the median conversion ",
      "ratio is 97.6, supporting conversion to centimetres with x100."
    ),
    "",
    stringr::str_c(
      "Source 243 (Niwot Alpine Plant Traits) contains Leaf Area values ",
      "with median 2.9442 and range 0.0524 to 47.327. Across 100 shared ",
      "taxa, the median conversion ratio is 94.21 and 77% fall within ",
      "25% of x100, supporting square centimetres to square millimetres."
    ),
    "",
    "## Additional approved source rules",
    "",
    stringr::str_c(
      "Source 187 (Abisko & Sheffield Database) contains 248 Plant heigh ",
      "records with median 0.15 and range 0.02 to 12, consistent with ",
      "metres. Source 457 (Alpine tundra plants) contains 127 records ",
      "with median 0.025 and range 0.002 to 0.11, also consistent with ",
      "metres. The project owner approved both x100 rules on 2026-08-30; ",
      "they apply to 248 and 127 records respectively."
    ),
    "",
    "## Rejected taxon-specific interpretation",
    "",
    stringr::str_c(
      "The earlier Poa sp and Prunella vulgaris x0.01 proposals are not ",
      "supported. Values near 30 to 50 are already plausible centimetres. ",
      "The apparent discrepancy is explained in the opposite direction ",
      "by metre-valued Tundra Trait Team records requiring source x100."
    ),
    "",
    stringr::str_c(
      "The approved ARCTOSTAPHYLOS UVA-URSI Plant heigh x0.01 threshold ",
      "rule is likewise superseded. It was inferred before source 155 was ",
      "corrected and would now shrink valid centimetre observations. The ",
      "canonical review records an approved residual none decision instead."
    ),
    "",
    stringr::str_c(
      "The approved Betula papyrifera Plant heigh x0.1 threshold rule is ",
      "also superseded. It was inferred before source 352 was corrected ",
      "and would partially reverse that source-wide x100 correction. The ",
      "canonical review records an approved residual none decision."
    ),
    "",
    "## Conservative decisions",
    "",
    stringr::str_c(
      "All Leaf mass per area exceptions resolve to no action. TRY-derived ",
      "Leaf mass per area remains provisional and unchanged because its ",
      "original units have not been reconstructed. Other isolated or ",
      "threshold-derived power-of-ten matches also resolve to no action ",
      "when they lack consistent source-level corroboration."
    ),
    "",
    "## Safeguards",
    "",
    "- All ten production source rules were owner-approved.",
    "- All ten rules are version-guarded source-scale inputs.",
    stringr::str_c(
      "- Twenty-nine affected current candidates have residual no-action ",
      "decisions."
    ),
    "- Six historical candidates retired because source scaling resolved them.",
    "- Forty post-investigation candidates resolve to no action.",
    "- Two newly exposed candidates retired after source scaling.",
    "- Every current raw candidate has an approved review decision.",
    "- Approved no-action decisions alter no trait records.",
    "- Production validation still fails closed on source or count drift."
  )

readr::write_csv(
  data_investigation_audit,
  path_investigation_audit,
  na = ""
)
readr::write_csv(
  data_pending_candidates,
  path_pending_candidates,
  na = ""
)
readr::write_csv(
  data_source_proposals,
  path_source_proposals,
  na = ""
)
readr::write_csv(
  data_follow_up_source_proposals,
  path_follow_up_source_proposals,
  na = ""
)
readr::write_csv(
  data_source_evidence,
  path_source_evidence,
  na = ""
)
base::writeLines(vec_report, con = path_report)
base::file.copy(
  from = path_pending_decisions,
  to = path_decisions_raw,
  overwrite = TRUE
)

data_written_decisions <-
  load_trait_review_decisions(path_decisions_raw)
assertthat::assert_that(
  base::nrow(data_written_decisions) == 4339L,
  base::sum(data_written_decisions[["action"]] == "none") == 4262L,
  msg = "Written grouped-investigation decisions are incomplete."
)

base::message(
  "Recorded conservative closure decisions and two historical source ",
  "supersessions; raw candidate coverage is complete."
)

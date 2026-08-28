#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Capture trait-review spot-check decisions
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This one-time provenance workflow records the project owner's reviewed
#   outcomes and assesses conservative expansion by rule stratum.

library(here)

source(here::here("R/___setup_project___.R"))

path_triage <-
  here::here(
    "Data/Temp/Trait_corrections/raw/programmatic_triage"
  )
path_decisions <-
  here::here(
    "Data/Input/Trait_corrections/",
    "trait_review_programmatic_spot_check_decisions.csv"
  )
evidence_reference <-
  stringr::str_c(
    "Outputs/Reports/Trait_corrections/raw/",
    "trait_review_programmatic_spot_check_report.md"
  )

data_spot_check <-
  readr::read_csv(
    base::file.path(
      path_triage,
      "trait_review_programmatic_spot_check.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
data_all_proposals <-
  readr::read_csv(
    base::file.path(
      path_triage,
      "trait_review_programmatic_decision_proposals.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
  dplyr::filter(.data[["action"]] == "scale")
data_proposal_audit <-
  readr::read_csv(
    base::file.path(
      path_triage,
      "trait_review_programmatic_proposal_audit.csv"
    ),
    show_col_types = FALSE,
    progress = FALSE
  )

data_reviewed_outcomes <-
  tibble::tribble(
    ~spot_check_id, ~source_decision_text, ~review_outcome,
    ~reviewer_note,
    "SC-01", "approve", "approve", "",
    "SC-02", "approve", "approve", "",
    "SC-03", "needs targeted review", "needs_targeted_review", "",
    "SC-04",
    "needs targeted review (can by multiplied by 100 instead of 10?)",
    "needs_targeted_review",
    "Investigate whether the factor should be 100 instead of 10.",
    "SC-05", "approve", "approve", "",
    "SC-06", "approve", "approve", "",
    "SC-07", "approve", "approve", "",
    "SC-08", "approve", "approve", "",
    "SC-09", "approve", "approve", "",
    "SC-10", "approve", "approve", "",
    "SC-11", "approve", "approve", "",
    "SC-12", "approve", "approve", "",
    "SC-13", "approve", "approve", "",
    "SC-14", "approve", "approve", "",
    "SC-15", "needs targeted review", "needs_targeted_review", "",
    "SC-16", "approve", "approve", "",
    "SC-17", "approve", "approve", "",
    "SC-18", "needs targeted review", "needs_targeted_review", "",
    "SC-19",
    "needs targeted review (multiply by 0.1?)",
    "needs_targeted_review",
    "Investigate whether the factor should be 0.1 instead of 0.01.",
    "SC-20", "needs targeted review", "needs_targeted_review", "",
    "SC-21", "aprrove", "approve",
    "Normalized the evident spelling error in the reviewed report.",
    "SC-22", "reject", "reject", "",
    "SC-23", "approve", "approve", "",
    "SC-24", "approve", "approve", ""
  )

data_decisions <-
  data_spot_check |>
  dplyr::select(
    "spot_check_id",
    "candidate_id",
    "decision_id",
    "taxon_name",
    "trait_domain_name",
    proposed_action = "action",
    proposed_scale_factor = "scale_factor"
  ) |>
  dplyr::inner_join(
    data_reviewed_outcomes,
    by = dplyr::join_by(spot_check_id),
    unmatched = "error",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    reviewer = "project_owner",
    reviewed_at = base::as.Date("2026-08-27"),
    evidence_reference = evidence_reference
  )

assertthat::assert_that(
  base::nrow(data_decisions) == 24L,
  !base::anyDuplicated(data_decisions[["spot_check_id"]]),
  !base::anyDuplicated(data_decisions[["candidate_id"]]),
  base::setequal(
    base::unique(data_decisions[["review_outcome"]]),
    base::c("approve", "reject", "needs_targeted_review")
  ),
  base::sum(data_decisions[["review_outcome"]] == "approve") == 17L,
  base::sum(data_decisions[["review_outcome"]] == "reject") == 1L,
  base::sum(
    data_decisions[["review_outcome"]] == "needs_targeted_review"
  ) == 6L,
  msg = "The captured spot-check decisions do not match the reviewed report."
)

data_all_proposal_strata <-
  data_all_proposals |>
  dplyr::left_join(
    data_proposal_audit |>
      dplyr::select(
        "candidate_id",
        "proposed_record_count"
      ),
    by = dplyr::join_by(candidate_id),
    relationship = "one-to-one"
  ) |>
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
data_reviewed_strata <-
  data_spot_check |>
  dplyr::select(
    "spot_check_id",
    "candidate_id"
  ) |>
  dplyr::inner_join(
    data_decisions |>
      dplyr::select(
        "spot_check_id",
        "review_outcome"
      ),
    by = dplyr::join_by(spot_check_id),
    unmatched = "error",
    relationship = "one-to-one"
  ) |>
  dplyr::inner_join(
    data_all_proposal_strata |>
      dplyr::select(
        "candidate_id",
        "rule_stratum"
    ),
    by = dplyr::join_by(candidate_id),
    unmatched = base::c("error", "drop"),
    relationship = "one-to-one"
  )
data_stratum_review_summary <-
  data_reviewed_strata |>
  dplyr::summarise(
    n_reviewed = dplyr::n(),
    n_approved = base::sum(.data[["review_outcome"]] == "approve"),
    n_rejected = base::sum(.data[["review_outcome"]] == "reject"),
    n_targeted = base::sum(
      .data[["review_outcome"]] == "needs_targeted_review"
    ),
    .by = "rule_stratum"
  )
data_stratum_assessment <-
  data_all_proposal_strata |>
  dplyr::summarise(
    trait_domain_name = dplyr::first(.data[["trait_domain_name"]]),
    rule_kind = dplyr::first(.data[["rule_kind"]]),
    threshold_direction = dplyr::first(.data[["threshold_direction"]]),
    scale_factor = dplyr::first(.data[["scale_factor"]]),
    n_proposals = dplyr::n(),
    n_records = base::sum(.data[["proposed_record_count"]]),
    .by = "rule_stratum"
  ) |>
  dplyr::left_join(
    data_stratum_review_summary,
    by = dplyr::join_by(rule_stratum),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    dplyr::across(
      dplyr::starts_with("n_reviewed") |
        dplyr::starts_with("n_approved") |
        dplyr::starts_with("n_rejected") |
        dplyr::starts_with("n_targeted"),
      ~ tidyr::replace_na(.x, 0L)
    ),
    expansion_assessment = dplyr::case_when(
      .data[["n_rejected"]] > 0L ~ "do_not_expand",
      .data[["n_targeted"]] > 0L ~ "needs_investigation",
      .data[["n_reviewed"]] > 0L &
        .data[["n_approved"]] == .data[["n_reviewed"]] ~
        "supports_conservative_expansion",
      TRUE ~ "not_reviewed"
    ),
    n_supported_proposals = dplyr::if_else(
      .data[["expansion_assessment"]] ==
        "supports_conservative_expansion",
      .data[["n_proposals"]],
      0L
    )
  ) |>
  dplyr::arrange(
    .data[["trait_domain_name"]],
    .data[["rule_kind"]],
    .data[["scale_factor"]]
  )

readr::write_csv(
  data_decisions,
  path_decisions,
  na = ""
)
readr::write_csv(
  data_stratum_assessment,
  base::file.path(
    path_triage,
    "trait_review_programmatic_spot_check_stratum_assessment.csv"
  ),
  na = ""
)

base::print(
  data_decisions |>
    dplyr::count(.data[["review_outcome"]])
)
base::print(
  data_stratum_assessment |>
    dplyr::summarise(
      n_supported_proposals = base::sum(
        .data[["n_supported_proposals"]]
      ),
      n_supported_records = base::sum(
        dplyr::if_else(
          .data[["expansion_assessment"]] ==
            "supports_conservative_expansion",
          .data[["n_records"]],
          0L
        )
      )
    )
)

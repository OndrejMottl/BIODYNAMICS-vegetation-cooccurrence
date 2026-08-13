#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#          Recover the trait review submission
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time provenance workflow. The immutable source is only read.
# Derived proposals remain unapproved and require scientific review.

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_submission <-
  here::here(
    "Data/Input/Trait_corrections/Review_submission/",
    "trait_manual_corrections.csv"
  )
path_output_directory <-
  here::here("Data/Temp/Trait_corrections/raw")

base::dir.create(
  path_output_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

data_submission_source <-
  readr::read_csv(
    path_submission,
    col_names = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    name_repair = "minimal",
    progress = FALSE,
    show_col_types = FALSE,
    trim_ws = FALSE
  )

data_submission_derived <-
  data_submission_source |>
  dplyr::transmute(
    source_row = dplyr::row_number(),
    taxon_name_source = .data[["X1"]],
    taxon_name = .data[["X1"]] |>
      stringr::str_replace_all("\u2212", "-") |>
      stringr::str_squish(),
    trait_domain_name_source = .data[["X2"]],
    trait_domain_name = stringr::str_squish(.data[["X2"]]),
    action_source = .data[["X3"]],
    action = stringr::str_to_lower(
      stringr::str_squish(.data[["X3"]])
    ),
    scale_factor_source = .data[["X4"]],
    scale_factor = readr::parse_double(
      .data[["X4"]],
      na = base::c("", "x", "e")
    ),
    notes_source = .data[["X5"]],
    notes = stringr::str_squish(.data[["X5"]]),
    checked_source = .data[["X6"]],
    has_taxon_unicode_minus = stringr::str_detect(
      .data[["X1"]],
      "\u2212"
    ),
    has_edge_whitespace =
      .data[["X1"]] != stringr::str_trim(.data[["X1"]]) |
      .data[["X2"]] != stringr::str_trim(.data[["X2"]]) |
      .data[["X3"]] != stringr::str_trim(.data[["X3"]]),
    has_stray_trailing_cell = base::apply(
      dplyr::pick(dplyr::matches("^X(?:[7-9]|1[0-9]|2[0-6])$")),
      1L,
      function(row_values) {
        base::any(!base::is.na(row_values) & row_values != "")
      }
    )
  ) |>
  dplyr::mutate(
    candidate_key = stringr::str_c(
      "raw",
      .data[["taxon_name"]],
      .data[["trait_domain_name"]],
      sep = "|"
    ),
    candidate_id = base::vapply(
      .data[["candidate_key"]],
      digest::digest,
      character(1L),
      algo = "sha256",
      serialize = FALSE
    ),
    notes_lower = stringr::str_to_lower(.data[["notes"]]),
    trait_name_to_exclude = dplyr::case_when(
      stringr::str_detect(
        .data[["notes_lower"]],
        "^use (the )?whole plant height( values)? only$"
      ) ~ "Plant height vegetative",
      stringr::str_detect(
        .data[["notes_lower"]],
        "^use (the )?plant height vegetative( values)? only$"
      ) ~ "whole plant height",
      TRUE ~ ""
    ),
    numeric_wording = stringr::str_extract(
      .data[["notes_lower"]],
      "(below|above|at)\\s+-?[0-9]+(?:\\.[0-9]+)?"
    ),
    numeric_operator = stringr::str_extract(
      .data[["numeric_wording"]],
      "below|above|at"
    ),
    numeric_value = readr::parse_double(
      stringr::str_extract(
        .data[["numeric_wording"]],
        "-?[0-9]+(?:\\.[0-9]+)?"
      )
    ),
    has_multiple_numeric_selectors = stringr::str_count(
      .data[["notes_lower"]],
      "(below|above|at)\\s+-?[0-9]+(?:\\.[0-9]+)?"
    ) > 1L,
    proposal_type = dplyr::case_when(
      .data[["trait_name_to_exclude"]] != "" ~
        "exclude_other_height_variant",
      .data[["action"]] == "exclude" &
        !base::is.na(.data[["numeric_operator"]]) &
        !.data[["has_multiple_numeric_selectors"]] ~
        "exclude_numeric_selector",
      .data[["action"]] == "scale" &
        !base::is.na(.data[["scale_factor"]]) &
        .data[["scale_factor"]] > 0 &
        (.data[["notes"]] == "" | base::is.na(.data[["notes"]])) ~
        "scale_whole_group",
      TRUE ~ "pending_visual_review"
    )
  )

data_proposals <-
  data_submission_derived |>
  dplyr::filter(
    .data[["proposal_type"]] != "pending_visual_review"
  ) |>
  dplyr::mutate(
    decision_key = stringr::str_c(
      .data[["source_row"]],
      .data[["candidate_id"]],
      .data[["proposal_type"]],
      sep = "|"
    ),
    decision_id = base::vapply(
      .data[["decision_key"]],
      digest::digest,
      character(1L),
      algo = "sha256",
      serialize = FALSE
    ),
    trait_name = .data[["trait_name_to_exclude"]],
    dataset_id = NA_integer_,
    value_lower = dplyr::if_else(
      .data[["numeric_operator"]] %in% base::c("above", "at"),
      .data[["numeric_value"]],
      NA_real_
    ),
    value_lower_inclusive = dplyr::case_when(
      .data[["numeric_operator"]] == "above" ~ FALSE,
      .data[["numeric_operator"]] == "at" ~ TRUE,
      TRUE ~ NA
    ),
    value_upper = dplyr::if_else(
      .data[["numeric_operator"]] %in% base::c("below", "at"),
      .data[["numeric_value"]],
      NA_real_
    ),
    value_upper_inclusive = dplyr::case_when(
      .data[["numeric_operator"]] == "below" ~ FALSE,
      .data[["numeric_operator"]] == "at" ~ TRUE,
      TRUE ~ NA
    ),
    action_proposed = dplyr::if_else(
      .data[["proposal_type"]] == "scale_whole_group",
      "scale",
      "exclude"
    ),
    scale_factor_proposed = dplyr::if_else(
      .data[["action_proposed"]] == "scale",
      .data[["scale_factor"]],
      NA_real_
    ),
    rationale = dplyr::if_else(
      base::is.na(.data[["notes"]]) | .data[["notes"]] == "",
      "Submitted review proposed whole-group rescaling.",
      .data[["notes"]]
    ),
    evidence_reference =
      "Review_submission/review_notes.pdf",
    source_reference = stringr::str_glue(
      "review_submission_csv:{.data[['source_row']]}"
    ),
    review_status = "proposed",
    reviewer = NA_character_,
    reviewed_at = NA_character_
  ) |>
  dplyr::transmute(
    decision_id = .data[["decision_id"]],
    candidate_id = .data[["candidate_id"]],
    taxon_name = .data[["taxon_name"]],
    trait_domain_name = .data[["trait_domain_name"]],
    trait_name = .data[["trait_name"]],
    dataset_id = .data[["dataset_id"]],
    value_lower = .data[["value_lower"]],
    value_lower_inclusive = .data[["value_lower_inclusive"]],
    value_upper = .data[["value_upper"]],
    value_upper_inclusive = .data[["value_upper_inclusive"]],
    action = .data[["action_proposed"]],
    scale_factor = .data[["scale_factor_proposed"]],
    rationale = .data[["rationale"]],
    evidence_reference = .data[["evidence_reference"]],
    source_reference = .data[["source_reference"]],
    review_status = .data[["review_status"]],
    reviewer = .data[["reviewer"]],
    reviewed_at = .data[["reviewed_at"]]
  )

readr::write_csv(
  data_submission_derived,
  base::file.path(
    path_output_directory,
    "review_submission_audit.csv"
  )
)
readr::write_csv(
  data_proposals,
  base::file.path(
    path_output_directory,
    "review_decision_proposals.csv"
  )
)
readr::write_csv(
  data_submission_derived |>
    dplyr::filter(
      .data[["proposal_type"]] == "pending_visual_review"
    ),
  base::file.path(
    path_output_directory,
    "review_pending_visual_review.csv"
  )
)

data_submission_derived |>
  dplyr::count(
    .data[["trait_domain_name"]],
    .data[["proposal_type"]]
  ) |>
  base::print(n = Inf)

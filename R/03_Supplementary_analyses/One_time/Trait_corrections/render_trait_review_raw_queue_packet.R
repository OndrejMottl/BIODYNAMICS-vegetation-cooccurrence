#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#      Render the review packet of the raw trait review queue
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time runner of the VegVault 2.0.0 migration (raw review queue).
# It prepares the material for a human reviewer of the cases that the
#   automated sorting left open, without the cases held for VegVault:
#   - a response sheet with one pre-filled row per case, the proposed
#     decision, and empty columns for the reviewer;
#   - a PDF packet with one page per case, rendered from
#     trait_review_raw_queue_packet.qmd in the same order as the sheet.
# Inputs: the draft resolutions and case evidence in
#   Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/
#   (written by Data/Temp/vegvault_2_migration/build_raw_queue_evidence.R),
#   the VegVault 2.0.0 trait store under Data/Temp, and
#   Data/Input/VegVault.sqlite (read-only, in the packet).
# Outputs (Outputs/Reports/Trait_corrections/raw/):
#   - trait_review_raw_queue_response_sheet.csv
#   - trait_review_raw_queue_packet.pdf
# The returned sheet is a review submission: keep it unchanged and record
#   the approved decisions in the release folder through
#   run_trait_review_vegvault_2_0_0_approval.R.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

dir_evidence <-
  here::here(
    "Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11"
  )

dir_output <-
  here::here("Outputs/Reports/Trait_corrections/raw")

file_sheet <-
  base::file.path(dir_output, "trait_review_raw_queue_response_sheet.csv")

name_packet <- "trait_review_raw_queue_packet.pdf"

path_packet_source <-
  here::here(
    "R/03_Supplementary_analyses/One_time/Trait_corrections",
    "trait_review_raw_queue_packet.qmd"
  )

assertthat::assert_that(
  base::dir.exists(dir_output),
  base::file.exists(path_packet_source),
  msg = "The report folder and the packet source must exist."
)


#----------------------------------------------------------#
# 1. Response sheet -----
#----------------------------------------------------------#

data_draft <-
  readr::read_csv(
    file = base::file.path(
      dir_evidence,
      "trait_review_raw_queue_draft_resolutions.csv"
    ),
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["action"]] %in% base::c("none", "exclude"))

data_case_evidence <-
  readr::read_csv(
    file = base::file.path(
      dir_evidence,
      "trait_review_raw_queue_case_evidence.csv"
    ),
    show_col_types = FALSE
  )

# The proposed dataset is named by its label on the case page: L for the
#   lowest and H for the highest median of the taxon
data_sheet <-
  data_draft |>
  dplyr::select(
    "candidate_id", "taxon_name", "trait_domain_name",
    "proposed_action_code" = "action",
    "proposed_dataset_id" = "dataset_id"
  ) |>
  dplyr::inner_join(
    data_case_evidence |>
      dplyr::select(
        "candidate_id", "trait_unit", "low_dataset_id", "high_dataset_id"
      ),
    by = dplyr::join_by("candidate_id"),
    multiple = "error",
    # Every draft has evidence; the evidence of held cases is dropped
    unmatched = base::c("error", "drop")
  ) |>
  dplyr::arrange(.data[["trait_domain_name"]], .data[["taxon_name"]]) |>
  dplyr::mutate(
    case = dplyr::row_number(),
    proposed_action = dplyr::if_else(
      .data[["proposed_action_code"]] == "none",
      "keep",
      "exclude"
    ),
    proposed_dataset = dplyr::case_when(
      .data[["proposed_dataset_id"]] == .data[["low_dataset_id"]] ~ "L",
      .data[["proposed_dataset_id"]] == .data[["high_dataset_id"]] ~ "H",
      .default = ""
    ),
    agree = "",
    reviewer_action = "",
    reviewer_dataset = "",
    reviewer_factor = "",
    reviewer_comment = ""
  ) |>
  dplyr::select(
    "case", "taxon_name", "trait_domain_name", "trait_unit",
    "proposed_action", "proposed_dataset",
    "low_dataset_id", "high_dataset_id",
    "agree", "reviewer_action", "reviewer_dataset", "reviewer_factor",
    "reviewer_comment", "candidate_id"
  )

assertthat::assert_that(
  !base::anyDuplicated(dplyr::pull(data_sheet, "candidate_id")),
  base::all(
    dplyr::pull(data_sheet, "proposed_dataset")[
      dplyr::pull(data_sheet, "proposed_action") == "exclude"
    ] %in% base::c("L", "H")
  ),
  msg = "Every case appears once, and every exclusion names L or H."
)

readr::write_csv(
  x = data_sheet,
  file = file_sheet,
  na = ""
)


#----------------------------------------------------------#
# 2. Packet -----
#----------------------------------------------------------#

# Quarto writes the PDF next to its source; it is moved to the reports
quarto::quarto_render(
  input = path_packet_source,
  output_file = name_packet
)

path_rendered_packet <-
  base::file.path(base::dirname(path_packet_source), name_packet)

assertthat::assert_that(
  base::file.exists(path_rendered_packet),
  msg = "The packet was not rendered."
)

path_packet <-
  base::file.path(dir_output, name_packet)

# A packet from an earlier run is replaced
if (
  base::file.exists(path_packet)
) {
  fs::file_delete(path_packet)
}

fs::file_move(
  path = path_rendered_packet,
  new_path = path_packet
)

cli::cli_inform(
  base::c(
    "v" = "{base::nrow(data_sheet)} cases written.",
    "i" = "Sheet: {.path {file_sheet}}",
    "i" = "Packet: {.path {path_packet}}"
  )
)

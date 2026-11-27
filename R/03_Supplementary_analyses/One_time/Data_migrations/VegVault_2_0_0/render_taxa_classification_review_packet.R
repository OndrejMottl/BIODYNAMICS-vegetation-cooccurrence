#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#    Render the review packet of the VegVault 2.0.0 taxa
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time runner of the VegVault 2.0.0 migration (taxon classification).
# It prepares the material for a human reviewer of the rows added to
#   Data/Input/aux_classification_table.csv for VegVault 2.0.0:
#   - the combined pollen types whose classification changes;
#   - the names that the automatic lookup leaves unclassified.
# Outputs (Outputs/Reports/Taxa_classification/):
#   - taxa_classification_review_response_sheet.csv: one pre-filled row
#     per name, the proposed classification, and empty columns for the
#     reviewer;
#   - taxa_classification_review_packet.pdf: the instructions and the
#     same rows as tables, rendered from
#     taxa_classification_review_packet.qmd.
# The rows are ordered from the least to the most certain: uncertain
#   readings, combined types across families, combined types within one
#   family, secure readings.
# Inputs: the V4 evidence in
#   Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/
#   (written by diagnose_taxa_classification_coverage.R and by the
#   helper Data/Temp/vegvault_2_migration/build_unclassified_name_drafts.R).
# The returned sheet is a review submission: keep it unchanged and change
#   the auxiliary table only where the review gives a reason.


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
  here::here("Outputs/Reports/Taxa_classification")

file_sheet <-
  base::file.path(
    dir_output,
    "taxa_classification_review_response_sheet.csv"
  )

name_packet <- "taxa_classification_review_packet.pdf"

path_packet_source <-
  here::here(
    "R/03_Supplementary_analyses/One_time/Data_migrations/VegVault_2_0_0",
    "taxa_classification_review_packet.qmd"
  )

assertthat::assert_that(
  base::file.exists(path_packet_source),
  msg = "The packet source must exist."
)

base::dir.create(dir_output, recursive = TRUE, showWarnings = FALSE)

vec_rank_columns <-
  base::c(
    "kingdom", "phylum", "class", "order", "family", "genus", "species"
  )

vec_group_labels <-
  base::c(
    "Uncertain readings",
    "Combined types across families",
    "Combined types within one family",
    "Secure readings"
  )


#----------------------------------------------------------#
# 1. Load the evidence -----
#----------------------------------------------------------#

data_combined_types <-
  readr::read_csv(
    file = base::file.path(dir_evidence, "taxa_combined_pollen_types.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["changes_classification"]] %in% TRUE)

data_unclassified_drafts <-
  readr::read_csv(
    file = base::file.path(
      dir_evidence,
      "taxa_unclassified_names_draft_rows.csv"
    ),
    col_types = readr::cols(.default = readr::col_character())
  )

data_names_to_resolve <-
  readr::read_csv(
    file = base::file.path(
      dir_evidence,
      "taxa_classification_names_to_resolve.csv"
    ),
    show_col_types = FALSE
  )

data_auxiliary_table <-
  load_auxiliary_classification_table()

assertthat::assert_that(
  base::nrow(data_combined_types) == 38L,
  base::nrow(data_unclassified_drafts) == 27L,
  base::all(
    base::c(
      data_combined_types[["taxon_name"]],
      data_unclassified_drafts[["sel_name"]]
    ) %in% data_auxiliary_table[["sel_name"]]
  ),
  msg = stringr::str_c(
    "The 38 combined types and 27 drafts must all be in the auxiliary ",
    "table."
  )
)


#----------------------------------------------------------#
# 2. Response sheet -----
#----------------------------------------------------------#

# The proposed classification is the row of the auxiliary table
data_proposed <-
  data_auxiliary_table |>
  dplyr::mutate(
    proposed_rank = dplyr::case_when(
      !base::is.na(.data[["species"]]) ~ "species",
      !base::is.na(.data[["genus"]]) ~ "genus",
      !base::is.na(.data[["family"]]) ~ "family",
      !base::is.na(.data[["order"]]) ~ "order",
      !base::is.na(.data[["class"]]) ~ "class",
      !base::is.na(.data[["phylum"]]) ~ "phylum",
      !base::is.na(.data[["kingdom"]]) ~ "kingdom",
      .default = "none"
    ),
    proposed_taxon = dplyr::coalesce(
      .data[["species"]], .data[["genus"]], .data[["family"]],
      .data[["order"]], .data[["class"]], .data[["phylum"]],
      .data[["kingdom"]], ""
    )
  ) |>
  tidyr::unite(
    col = "proposed_lineage",
    dplyr::all_of(base::c("class", "order", "family", "genus")),
    sep = " > ",
    na.rm = TRUE
  ) |>
  dplyr::select(
    "taxon_name" = "sel_name",
    "proposed_rank", "proposed_taxon", "proposed_lineage"
  )

data_sheet_combined <-
  data_combined_types |>
  dplyr::mutate(
    group = dplyr::if_else(
      .data[["proposal_rule"]] == "lowest_shared_rank",
      vec_group_labels[[2L]],
      vec_group_labels[[3L]]
    ),
    confidence = NA_character_,
    # The current placement is shown from the genus up; the analyses do
    #   not use the species of a pollen type
    current_taxon = dplyr::case_when(
      !base::is.na(.data[["project_genus"]]) ~
        stringr::str_c("genus ", .data[["project_genus"]]),
      !base::is.na(.data[["project_family"]]) ~
        stringr::str_c("family ", .data[["project_family"]]),
      !base::is.na(.data[["project_order"]]) ~
        stringr::str_c("order ", .data[["project_order"]]),
      !base::is.na(.data[["project_class"]]) ~
        stringr::str_c("class ", .data[["project_class"]]),
      .default = "unclassified"
    ),
    parts = stringr::str_replace_all(.data[["genera"]], "/", ", "),
    reasoning = dplyr::if_else(
      .data[["proposal_rule"]] == "lowest_shared_rank",
      stringr::str_c(
        "The parts (", .data[["parts"]], ") belong to different ",
        "families, and VegVault 2.0.0 leaves the type unclassified. ",
        "The row places it at the lowest rank the parts share."
      ),
      stringr::str_c(
        "VegVault 2.0.0 places the type in the family ",
        .data[["vegvault_2_0_0_family"]], ". The row follows it and ",
        "leaves the genus empty."
      )
    )
  ) |>
  dplyr::select(
    "group", "taxon_name", "continent_ids", "data_types", "n_samples",
    "current_taxon", "confidence", "reasoning"
  )

data_sheet_unclassified <-
  data_unclassified_drafts |>
  dplyr::inner_join(
    data_names_to_resolve |>
      dplyr::select(
        "sel_name" = "taxon_name",
        "continent_ids", "data_types", "n_samples",
        "lookup_genus" = "genus", "lookup_family" = "family"
      ),
    by = dplyr::join_by("sel_name"),
    multiple = "error",
    unmatched = base::c("error", "drop")
  ) |>
  dplyr::mutate(
    group = dplyr::if_else(
      .data[["confidence"]] == "high",
      vec_group_labels[[4L]],
      vec_group_labels[[1L]]
    ),
    current_taxon = dplyr::case_when(
      !base::is.na(.data[["lookup_genus"]]) ~
        stringr::str_c("genus ", .data[["lookup_genus"]]),
      !base::is.na(.data[["lookup_family"]]) ~
        stringr::str_c("family ", .data[["lookup_family"]]),
      .default = "unclassified"
    ),
    reasoning = dplyr::if_else(
      .data[["readings"]] == "none",
      .data[["rationale"]],
      stringr::str_c(
        "Likely meant: ",
        stringr::str_replace_all(.data[["readings"]], "\\|", " or "),
        ". ", .data[["rationale"]]
      )
    )
  ) |>
  dplyr::select(
    "group", "taxon_name" = "sel_name", "continent_ids", "data_types",
    "n_samples", "current_taxon", "confidence", "reasoning"
  )

data_sheet <-
  dplyr::bind_rows(data_sheet_combined, data_sheet_unclassified) |>
  dplyr::inner_join(
    data_proposed,
    by = dplyr::join_by("taxon_name"),
    multiple = "error",
    unmatched = base::c("error", "drop")
  ) |>
  dplyr::mutate(
    group_order = base::match(.data[["group"]], vec_group_labels),
    confidence_order = base::match(
      .data[["confidence"]],
      base::c("low", "medium", "high")
    ),
    data_type = dplyr::case_when(
      .data[["data_types"]] == "fossil_pollen_archive" ~ "fossil pollen",
      .data[["data_types"]] == "traits" ~ "traits",
      .default = .data[["data_types"]]
    ),
    continents = .data[["continent_ids"]] |>
      stringr::str_replace_all("\\|", ", ") |>
      stringr::str_to_title()
  ) |>
  dplyr::arrange(
    .data[["group_order"]],
    .data[["confidence_order"]],
    .data[["taxon_name"]]
  ) |>
  dplyr::mutate(
    case = dplyr::row_number(),
    agree = "",
    reviewer_rank = "",
    reviewer_taxon = "",
    reviewer_comment = ""
  ) |>
  dplyr::select(
    "case", "group", "taxon_name", "data_type", "continents", "n_samples",
    "current_taxon", "proposed_rank", "proposed_taxon", "proposed_lineage",
    "confidence", "reasoning",
    "agree", "reviewer_rank", "reviewer_taxon", "reviewer_comment"
  )

assertthat::assert_that(
  base::nrow(data_sheet) == 65L,
  !base::anyDuplicated(dplyr::pull(data_sheet, "taxon_name")),
  !base::anyNA(dplyr::pull(data_sheet, "reasoning")),
  msg = "The sheet holds each of the 65 names once, each with a reason."
)

readr::write_csv(
  x = data_sheet,
  file = file_sheet,
  na = ""
)


#----------------------------------------------------------#
# 3. Packet -----
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
    "v" = "{base::nrow(data_sheet)} names written.",
    "i" = "Sheet: {.path {file_sheet}}",
    "i" = "Packet: {.path {path_packet}}"
  )
)

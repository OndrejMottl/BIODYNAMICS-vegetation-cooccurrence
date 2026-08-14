#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#        Extract historical trait-review scope
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time provenance workflow for archived trait QC reports.

path_repository_root <-
  here::here()
path_report_directory <-
  here::here("Outputs/Reports")
path_historical_scope_output <-
  here::here(
    "Data/Temp/Trait_corrections/raw/",
    "historical_review_scope.csv"
  )

data_report_specs <-
  tibble::tribble(
    ~trait_domain_name, ~report_file, ~expected_groups,
    ~reviewed_through_page, ~historical_review_basis,
    "Diaspore mass",
    "trait_qc_Diaspore_mass_2026-04-10.pdf",
    43L,
    NA_integer_,
    "complete domain review recorded in review note",
    "Leaf Area",
    "trait_qc_Leaf_Area_2026-04-10.pdf",
    1095L,
    700L,
    "partial review recorded through PDF page 700",
    "Leaf mass per area",
    "trait_qc_Leaf_mass_per_area_2026-04-10.pdf",
    1371L,
    0L,
    "domain absent from submitted review record",
    "Leaf nitrogen content per unit mass",
    "trait_qc_Leaf_nitrogen_content_per_unit_mass_2026-04-10.pdf",
    518L,
    NA_integer_,
    "complete domain review recorded in review note",
    "Plant heigh",
    "trait_qc_Plant_heigh_2026-04-10.pdf",
    1150L,
    NA_integer_,
    "complete domain review recorded in review note",
    "Stem specific density",
    "trait_qc_Stem_specific_density_2026-04-10.pdf",
    101L,
    NA_integer_,
    "complete domain review recorded in review note"
  )

list_historical_scope <-
  base::vector(
    mode = "list",
    length = base::nrow(data_report_specs)
  )

for (
  index_report in base::seq_len(base::nrow(data_report_specs))
) {
  trait_domain_name <-
    data_report_specs[["trait_domain_name"]][[index_report]]
  report_file <-
    data_report_specs[["report_file"]][[index_report]]
  path_report <-
    base::file.path(path_report_directory, report_file)

  assertthat::assert_that(
    base::file.exists(path_report),
    msg = stringr::str_c("Historical report not found: ", path_report)
  )

  vec_page_text <-
    pdftools::pdf_text(path_report)
  pattern_footer <-
    stringr::str_c(
      "([^\\n]+?)\\s+—\\s+",
      trait_domain_name,
      "\\s*$"
    )
  list_report_rows <-
    base::vector(
      mode = "list",
      length = base::length(vec_page_text) - 1L
    )
  index_group <- 0L

  for (
    index_page in base::seq_along(vec_page_text)[-1L]
  ) {
    mat_footer <-
      stringr::str_match(
        vec_page_text[[index_page]],
        stringr::regex(pattern_footer, multiline = TRUE)
      )
    if (
      base::is.na(mat_footer[1L, 2L])
    ) {
      next
    }

    index_group <- index_group + 1L
    taxon_name <-
      stringr::str_trim(mat_footer[1L, 2L])
    reviewed_through_page <-
      data_report_specs[["reviewed_through_page"]][[index_report]]
    historical_reviewed <-
      base::is.na(reviewed_through_page) |
        index_page <= reviewed_through_page
    candidate_key <-
      stringr::str_c(
        "raw",
        taxon_name,
        trait_domain_name,
        sep = "|"
      )

    list_report_rows[[index_group]] <-
      tibble::tibble(
        candidate_id = digest::digest(
          candidate_key,
          algo = "sha256",
          serialize = FALSE
        ),
        taxon_name = taxon_name,
        trait_domain_name = trait_domain_name,
        historical_report_path = stringr::str_c(
          "Outputs/Reports/",
          report_file
        ),
        historical_report_page = index_page,
        historical_reviewed = historical_reviewed,
        historical_review_basis =
          data_report_specs[["historical_review_basis"]][[index_report]]
      )
  }

  data_report_scope <-
    dplyr::bind_rows(list_report_rows)
  expected_groups <-
    data_report_specs[["expected_groups"]][[index_report]]
  assertthat::assert_that(
    base::nrow(data_report_scope) == expected_groups,
    msg = stringr::str_c(
      "Expected ",
      expected_groups,
      " groups for ",
      trait_domain_name,
      ", found ",
      base::nrow(data_report_scope),
      "."
    )
  )
  list_historical_scope[[index_report]] <- data_report_scope
}

data_historical_scope <-
  dplyr::bind_rows(list_historical_scope)
assertthat::assert_that(
  !base::anyDuplicated(data_historical_scope[["candidate_id"]]),
  msg = "Historical reports contain duplicate candidate IDs."
)

base::dir.create(
  base::dirname(path_historical_scope_output),
  recursive = TRUE,
  showWarnings = FALSE
)
readr::write_csv(
  data_historical_scope,
  path_historical_scope_output
)

base::message(
  stringr::str_c(
    "Wrote ",
    base::nrow(data_historical_scope),
    " historical groups; ",
    base::sum(data_historical_scope[["historical_reviewed"]]),
    " reviewed."
  )
)

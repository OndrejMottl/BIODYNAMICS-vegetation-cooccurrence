#' @title Load Trait Source Scale Rules
#' @description
#' Strictly loads the canonical VegVault source-scale rule CSV.
#' @param path_trait_source_scale_rules
#' Character scalar path to a canonical source-scale rule CSV.
#' @return
#' A typed tibble containing the canonical source-scale rule columns.
#' @export
load_trait_source_scale_rules <- function(
    path_trait_source_scale_rules) {
  assertthat::assert_that(
    base::is.character(path_trait_source_scale_rules) &&
      base::length(path_trait_source_scale_rules) == 1L &&
      base::file.exists(path_trait_source_scale_rules),
    msg = paste0(
      "'path_trait_source_scale_rules' must identify an existing file."
    )
  )

  canonical_columns <-
    base::c(
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
  data_header <-
    readr::read_csv(
      path_trait_source_scale_rules,
      n_max = 0L,
      name_repair = "minimal",
      show_col_types = FALSE,
      progress = FALSE,
      trim_ws = FALSE
    )
  if (
    !base::identical(base::names(data_header), canonical_columns)
  ) {
    cli::cli_abort(
      "Trait source scale rules must use canonical columns in order."
    )
  }

  rule_column_types <-
    readr::cols(
      source_scale_rule_id = readr::col_character(),
      vegvault_version = readr::col_character(),
      data_source_id = readr::col_integer(),
      expected_data_source_desc = readr::col_character(),
      trait_domain_name = readr::col_character(),
      trait_name = readr::col_character(),
      scale_factor = readr::col_double(),
      expected_match_count = readr::col_integer(),
      rationale = readr::col_character(),
      evidence_reference = readr::col_character(),
      review_status = readr::col_character(),
      reviewer = readr::col_character(),
      reviewed_at = readr::col_character()
    )
  data_rules <-
    readr::read_csv(
      path_trait_source_scale_rules,
      col_types = rule_column_types,
      name_repair = "minimal",
      na = "",
      progress = FALSE,
      trim_ws = FALSE
    )
  if (
    base::nrow(readr::problems(data_rules)) > 0L
  ) {
    cli::cli_abort("Trait source scale rules contain parsing problems.")
  }

  return(data_rules)
}

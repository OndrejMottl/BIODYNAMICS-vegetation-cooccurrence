#' @title Load Trait Review Decisions
#' @description
#' Strictly loads a canonical trait-review decision CSV.
#' @param path_trait_review_decisions
#' Character scalar path to a canonical decision CSV.
#' @return
#' A typed tibble containing the canonical decision columns.
#' @export
load_trait_review_decisions <- function(path_trait_review_decisions) {
  assertthat::assert_that(
    base::is.character(path_trait_review_decisions) &&
      base::length(path_trait_review_decisions) == 1L &&
      base::file.exists(path_trait_review_decisions),
    msg = "'path_trait_review_decisions' must identify an existing file."
  )

  canonical_columns <-
    base::c(
      "decision_id",
      "candidate_id",
      "taxon_name",
      "trait_domain_name",
      "trait_name",
      "dataset_id",
      "value_lower",
      "value_lower_inclusive",
      "value_upper",
      "value_upper_inclusive",
      "action",
      "scale_factor",
      "rationale",
      "evidence_reference",
      "source_reference",
      "review_status",
      "reviewer",
      "reviewed_at"
    )

  data_header <-
    readr::read_csv(
      path_trait_review_decisions,
      n_max = 0L,
      name_repair = "minimal",
      show_col_types = FALSE,
      progress = FALSE,
      trim_ws = FALSE
    )
  if (!base::identical(base::names(data_header), canonical_columns)) {
    cli::cli_abort(
      "Trait review decisions must use the canonical columns in order."
    )
  }

  decision_column_types <-
    readr::cols(
      decision_id = readr::col_character(),
      candidate_id = readr::col_character(),
      taxon_name = readr::col_character(),
      trait_domain_name = readr::col_character(),
      trait_name = readr::col_character(),
      dataset_id = readr::col_integer(),
      value_lower = readr::col_double(),
      value_lower_inclusive = readr::col_logical(),
      value_upper = readr::col_double(),
      value_upper_inclusive = readr::col_logical(),
      action = readr::col_character(),
      scale_factor = readr::col_double(),
      rationale = readr::col_character(),
      evidence_reference = readr::col_character(),
      source_reference = readr::col_character(),
      review_status = readr::col_character(),
      reviewer = readr::col_character(),
      reviewed_at = readr::col_character()
    )

  data_decisions <-
    readr::read_csv(
      path_trait_review_decisions,
      col_types = decision_column_types,
      name_repair = "minimal",
      na = "",
      progress = FALSE,
      trim_ws = FALSE
    )
  if (base::nrow(readr::problems(data_decisions)) > 0L) {
    cli::cli_abort("Trait review decisions contain parsing problems.")
  }

  return(data_decisions)
}

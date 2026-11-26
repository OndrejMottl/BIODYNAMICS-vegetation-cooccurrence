#' @title Load Trait Domain Units
#' @description
#' Strictly loads the reviewed table that records one unit per trait domain
#' for one VegVault release (`trait_domain_units.csv` in the release folder
#' of the trait corrections).
#' @param path_trait_domain_units
#' Character scalar path to a canonical trait-domain unit CSV.
#' @return
#' A typed tibble with the columns `vegvault_version`,
#' `vegvault_build_reference`, `trait_domain_name`, `trait_unit`,
#' `evidence_status`, `included_in_primary` (logical), `rationale`,
#' `evidence_reference`, `review_status`, `reviewer`, and `reviewed_at`.
#' @details
#' The header must hold the canonical columns in order. Empty cells are read
#' as `NA`, and cell text is not trimmed, so that
#' [validate_trait_domain_units()] can reject edge whitespace. The function
#' stops when any cell cannot be parsed to its column type.
#' @seealso [validate_trait_domain_units()],
#'   [resolve_trait_correction_directory()]
#' @export
load_trait_domain_units <- function(path_trait_domain_units) {
  assertthat::assert_that(
    base::is.character(path_trait_domain_units) &&
      base::length(path_trait_domain_units) == 1L &&
      !base::is.na(path_trait_domain_units) &&
      base::file.exists(path_trait_domain_units),
    msg = "'path_trait_domain_units' must identify one existing file."
  )

  unit_column_types <-
    readr::cols(
      vegvault_version = readr::col_character(),
      vegvault_build_reference = readr::col_character(),
      trait_domain_name = readr::col_character(),
      trait_unit = readr::col_character(),
      evidence_status = readr::col_character(),
      included_in_primary = readr::col_logical(),
      rationale = readr::col_character(),
      evidence_reference = readr::col_character(),
      review_status = readr::col_character(),
      reviewer = readr::col_character(),
      reviewed_at = readr::col_character()
    )

  data_header <-
    readr::read_csv(
      path_trait_domain_units,
      n_max = 0L,
      name_repair = "minimal",
      show_col_types = FALSE,
      progress = FALSE,
      trim_ws = FALSE
    )

  if (
    !base::identical(
      base::names(data_header),
      base::names(unit_column_types[["cols"]])
    )
  ) {
    cli::cli_abort(
      "Trait domain units must use the canonical columns in order."
    )
  }

  # Parsing problems become the error below, so readr's own warning about
  #   them is muffled
  data_trait_domain_units <-
    base::withCallingHandlers(
      expr = readr::read_csv(
        path_trait_domain_units,
        col_types = unit_column_types,
        name_repair = "minimal",
        na = "",
        progress = FALSE,
        trim_ws = FALSE
      ),
      vroom_parse_issue = function(condition) {
        base::invokeRestart("muffleWarning")
      }
    )

  if (
    base::nrow(readr::problems(data_trait_domain_units)) > 0L
  ) {
    cli::cli_abort("Trait domain units contain parsing problems.")
  }

  return(data_trait_domain_units)
}

#' @title Summarise Trait Coverage of Community Taxa
#' @description
#' Compares a character vector of taxon names from the community data
#' against the taxa present in a wide-format trait table. Reports the
#' proportion of community taxa covered by trait data and identifies
#' which taxa are missing or extra.
#' @param community_taxa
#' A character vector of unique taxon names from the community data.
#' @param data_trait_table
#' A wide-format trait table as returned by [build_trait_table()], with
#' a `taxon_name` column.
#' @return
#' A named list with the following elements:
#' \describe{
#'   \item{n_community_taxa}{Total number of unique taxa in the
#'     community vector.}
#'   \item{n_covered_taxa}{Number of community taxa present in the trait
#'     table.}
#'   \item{coverage_percent}{Coverage as a percentage, rounded to one
#'     decimal place.}
#'   \item{missing_taxa}{Character vector of community taxa
#'     absent from the trait table.}
#'   \item{extra_taxa}{Character vector of taxa in the trait
#'     table not found in the community.}
#' }
#' @details
#' A summary of coverage statistics is printed to the console via
#' `cli::cli_inform()`.
#' @seealso [build_trait_table()]
#' @export
summarise_trait_coverage <- function(
    community_taxa,
    data_trait_table) {
  assertthat::assert_that(
    base::is.character(community_taxa) &&
      base::length(community_taxa) > 0L,
    msg = base::paste0(
      "'community_taxa' must be a non-empty ",
      "character vector."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_trait_table),
    msg = "'data_trait_table' must be a data frame."
  )

  assertthat::assert_that(
    "taxon_name" %in% base::colnames(data_trait_table),
    msg = base::paste0(
      "'data_trait_table' must contain a 'taxon_name' column."
    )
  )

  trait_taxa <-
    data_trait_table |>
    dplyr::pull(.data[["taxon_name"]])

  n_community_taxa <-
    base::length(community_taxa)

  covered_taxa <-
    base::intersect(community_taxa, trait_taxa)

  n_covered_taxa <-
    base::length(covered_taxa)

  coverage_percent <-
    base::round(n_covered_taxa / n_community_taxa * 100, 1)

  missing_taxa <-
    base::setdiff(community_taxa, trait_taxa)

  extra_taxa <-
    base::setdiff(trait_taxa, community_taxa)

  cli::cli_inform(
    base::c(
      "i" = base::paste0(
        "Trait coverage: ", n_covered_taxa, " / ",
        n_community_taxa, " community taxa (",
        coverage_percent, "%)."
      ),
      "i" = base::paste0(
        base::length(missing_taxa),
        " taxa missing from trait table; ",
        base::length(extra_taxa),
        " extra taxa in trait table."
      )
    )
  )

  trait_coverage_summary <-
    base::list(
      n_community_taxa = n_community_taxa,
      n_covered_taxa = n_covered_taxa,
      coverage_percent = coverage_percent,
      missing_taxa = missing_taxa,
      extra_taxa = extra_taxa
    )

  return(trait_coverage_summary)
}

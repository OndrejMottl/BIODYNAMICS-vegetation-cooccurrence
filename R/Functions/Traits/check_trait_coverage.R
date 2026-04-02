#' @title Check Trait Coverage Against Community Taxa
#' @description
#' Compares a character vector of taxon names from the community data
#' against the taxa present in a wide-format trait table. Reports the
#' proportion of community taxa covered by trait data and identifies
#' which taxa are missing or extra.
#' @param vec_community_taxa
#' A character vector of unique taxon names from the community data.
#' @param data_trait_table
#' A wide-format trait table as returned by [make_trait_table()], with
#' a `taxon_name` column.
#' @return
#' A named list with the following elements:
#' \describe{
#'   \item{n_community_taxa}{Total number of unique taxa in the
#'     community vector.}
#'   \item{n_covered}{Number of community taxa present in the trait
#'     table.}
#'   \item{pct_covered}{Coverage as a percentage, rounded to one
#'     decimal place.}
#'   \item{vec_missing_taxa}{Character vector of community taxa
#'     absent from the trait table.}
#'   \item{vec_extra_taxa}{Character vector of taxa in the trait
#'     table not found in the community.}
#' }
#' @details
#' A summary of coverage statistics is printed to the console via
#' `cli::cli_inform()`.
#' @seealso [make_trait_table()]
#' @export
check_trait_coverage <- function(
    vec_community_taxa,
    data_trait_table) {
  assertthat::assert_that(
    base::is.character(vec_community_taxa) &&
      base::length(vec_community_taxa) > 0L,
    msg = paste0(
      "'vec_community_taxa' must be a non-empty ",
      "character vector."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_trait_table),
    msg = "'data_trait_table' must be a data frame."
  )

  assertthat::assert_that(
    "taxon_name" %in% base::colnames(data_trait_table),
    msg = paste0(
      "'data_trait_table' must contain a 'taxon_name' column."
    )
  )

  vec_trait_genera <-
    data_trait_table |>
    dplyr::pull(taxon_name)

  n_community_taxa <-
    base::length(vec_community_taxa)

  vec_covered <-
    base::intersect(vec_community_taxa, vec_trait_genera)

  n_covered <-
    base::length(vec_covered)

  pct_covered <-
    base::round(n_covered / n_community_taxa * 100, 1)

  vec_missing_taxa <-
    base::setdiff(vec_community_taxa, vec_trait_genera)

  vec_extra_taxa <-
    base::setdiff(vec_trait_genera, vec_community_taxa)

  cli::cli_inform(
    c(
      "i" = base::paste0(
        "Trait coverage: ", n_covered, " / ",
        n_community_taxa, " community taxa (",
        pct_covered, "%)."
      ),
      "i" = base::paste0(
        base::length(vec_missing_taxa),
        " taxa missing from trait table; ",
        base::length(vec_extra_taxa),
        " extra taxa in trait table."
      )
    )
  )

  res <-
    base::list(
      n_community_taxa = n_community_taxa,
      n_covered = n_covered,
      pct_covered = pct_covered,
      vec_missing_taxa = vec_missing_taxa,
      vec_extra_taxa = vec_extra_taxa
    )

  return(res)
}

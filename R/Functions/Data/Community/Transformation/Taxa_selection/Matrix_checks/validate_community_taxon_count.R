#' @title Validate Community Taxon Count
#' @description
#' Validates that a community matrix contains enough taxa for model fitting.
#' Returns the matrix unchanged when the number of taxa is at least
#' `minimum_taxon_count`.
#' Stops with an informative error when the column count is
#' below the threshold, preventing wasteful model fitting and
#' meaningless species–species associations from near-empty
#' communities.
#' @param data_community_matrix
#' A numeric matrix with samples as rows and taxa as columns,
#' as returned by `filter_constant_taxa()`.
#' @param minimum_taxon_count
#' A single positive integer giving the minimum number of taxa
#' (columns) required to proceed with model fitting. Default
#' is 5.
#' @return
#' The input matrix `data_community_matrix` unchanged, when
#' `ncol(data_community_matrix) >= minimum_taxon_count`.
#' @details
#' The check counts `ncol(data_community_matrix)` after all
#' upstream taxon-level filtering
#' (`filter_community_by_minimum_proportion()`,
#' `filter_community_by_minimum_core_count()`,
#' `filter_community_by_minimum_sample_count()`,
#' `filter_constant_taxa()`) has been applied. If the count
#' falls below `minimum_taxon_count`, `cli::cli_abort()` is called with
#' a message that reports the actual count and the threshold,
#' allowing the user to adjust the configuration or the data.
#' @seealso [filter_constant_taxa()], [assemble_data_to_fit()]
#' @export
validate_community_taxon_count <- function(
    data_community_matrix = NULL,
    minimum_taxon_count = 5) {
  assertthat::assert_that(
    base::is.matrix(data_community_matrix),
    msg = "data_community_matrix must be a matrix"
  )

  assertthat::assert_that(
    base::is.numeric(minimum_taxon_count) &&
      base::length(minimum_taxon_count) == 1L,
    msg = "minimum_taxon_count must be a numeric scalar"
  )

  assertthat::assert_that(
    minimum_taxon_count >= 1,
    msg = "minimum_taxon_count must be greater than or equal to 1"
  )

  taxon_count <-
    base::ncol(data_community_matrix)

  if (
    taxon_count < minimum_taxon_count
  ) {
    cli::cli_abort(
      base::c(
        stringr::str_c(
          "Too few taxa remain after filtering to run",
          " the model."
        ),
        "i" = stringr::str_c(
          "Found {taxon_count} taxa but at least",
          " {minimum_taxon_count} are required."
        ),
        "i" = stringr::str_c(
          "Adjust the minimum taxon count in the configuration",
          " or review upstream filtering steps."
        )
      )
    )
  }

  return(data_community_matrix)
}

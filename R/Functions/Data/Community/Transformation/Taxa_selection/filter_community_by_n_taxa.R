#' @title Filter Community Matrix by Minimum Number of Taxa
#' @description
#' Guards against running a joint species distribution model on
#' data with too few taxa. Returns the matrix unchanged when
#' the number of taxa (columns) is at least `min_n_taxa`.
#' Stops with an informative error when the column count is
#' below the threshold, preventing wasteful model fitting and
#' meaningless species–species associations from near-empty
#' communities.
#' @param data_community_matrix
#' A numeric matrix with samples as rows and taxa as columns,
#' as returned by `filter_constant_taxa()`.
#' @param min_n_taxa
#' A single positive integer giving the minimum number of taxa
#' (columns) required to proceed with model fitting. Default
#' is 5.
#' @return
#' The input matrix `data_community_matrix` unchanged, when
#' `ncol(data_community_matrix) >= min_n_taxa`.
#' @details
#' The check counts `ncol(data_community_matrix)` after all
#' upstream taxon-level filtering (`filter_rare_taxa()`,
#' `filter_community_by_n_cores()`, `filter_by_n_samples()`,
#' `filter_constant_taxa()`) has been applied. If the count
#' falls below `min_n_taxa`, `cli::cli_abort()` is called with
#' a message that reports the actual count and the threshold,
#' allowing the user to adjust the configuration or the data.
#' @seealso [filter_constant_taxa()], [assemble_data_to_fit()]
#' @export
filter_community_by_n_taxa <- function(
    data_community_matrix = NULL,
    min_n_taxa = 5) {
  assertthat::assert_that(
    base::is.matrix(data_community_matrix),
    msg = paste0(
      "data_community_matrix must be a matrix"
    )
  )

  assertthat::assert_that(
    base::is.numeric(min_n_taxa) &&
      base::length(min_n_taxa) == 1,
    msg = "min_n_taxa must be a single numeric value"
  )

  assertthat::assert_that(
    min_n_taxa >= 1,
    msg = "min_n_taxa must be greater than or equal to 1"
  )

  n_taxa <-
    base::ncol(data_community_matrix)

  if (
    n_taxa < min_n_taxa
  ) {
    cli::cli_abort(
      c(
        paste0(
          "Too few taxa remain after filtering to run",
          " the model."
        ),
        "i" = paste0(
          "Found {n_taxa} taxa but at least",
          " {min_n_taxa} are required."
        ),
        "i" = paste0(
          "Adjust `min_n_taxa` in the configuration",
          " or review upstream filtering steps."
        )
      )
    )
  }

  return(data_community_matrix)
}

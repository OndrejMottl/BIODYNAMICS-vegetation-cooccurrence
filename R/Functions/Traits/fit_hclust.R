#' @title Fit Hierarchical Clustering from a Distance Matrix
#' @description
#' Fits a hierarchical clustering model from a precomputed
#' dissimilarity matrix using `stats::hclust()`.
#' @param dist_mat
#' A `"dist"` object (as produced by `compute_dissimilarity_matrix()`
#' or `stats::as.dist()`). Must contain no `NA` or non-finite
#' values.
#' @param method
#' A single character string passed to `stats::hclust()` as the
#' `method` argument. Default: `"ward.D2"`. See `?stats::hclust`
#' for all valid linkage methods.
#' @return
#' An object of class `"hclust"` as returned by `stats::hclust()`.
#' @seealso [compute_dissimilarity_matrix()],
#'   [cluster_functional_types()]
#' @export
fit_hclust <- function(
    dist_mat,
    method = "ward.D2") {
  assertthat::assert_that(
    base::inherits(dist_mat, "dist"),
    msg = "'dist_mat' must be a 'dist' object."
  )

  assertthat::assert_that(
    base::is.character(method) &&
      base::length(method) == 1L,
    msg = "'method' must be a single character string."
  )

  res <-
    stats::hclust(
      dist_mat,
      method = method
    )

  return(res)
}

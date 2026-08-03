#' @title Fit Hierarchical Clustering from a Distance Matrix
#' @description
#' Fits a hierarchical clustering model from a precomputed
#' dissimilarity matrix using `stats::hclust()`.
#' @param trait_dissimilarity
#' A `"dist"` object (as produced by `compute_trait_dissimilarity()`
#' or `stats::as.dist()`). Must contain no `NA` or non-finite
#' values.
#' @param clustering_method
#' A single character string passed to `stats::hclust()` as the
#' `method` argument. Default: `"ward.D2"`. See `?stats::hclust`
#' for all valid linkage methods.
#' @return
#' An object of class `"hclust"` as returned by `stats::hclust()`.
#' @seealso [compute_trait_dissimilarity()],
#'   [assign_functional_type_clusters()]
#' @export
fit_hierarchical_clustering <- function(
    trait_dissimilarity,
    clustering_method = "ward.D2") {
  assertthat::assert_that(
    base::inherits(trait_dissimilarity, "dist"),
    msg = "'trait_dissimilarity' must be a 'dist' object."
  )

  assertthat::assert_that(
    base::is.character(clustering_method) &&
      base::length(clustering_method) == 1L,
    msg = "'clustering_method' must be a single character string."
  )

  hierarchical_clustering <-
    stats::hclust(
      trait_dissimilarity,
      method = clustering_method
    )

  return(hierarchical_clustering)
}

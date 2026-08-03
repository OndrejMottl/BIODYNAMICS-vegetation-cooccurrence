#' @title Assign Functional-Type Clusters
#' @description
#' Assigns taxa into functional types (FTs) using a pre-computed
#' Gower dissimilarity matrix, a pre-fitted hierarchical
#' clustering object, and a predetermined number of groups
#' `functional_type_group_count`. The number of groups is expected to
#' have been chosen upstream via `select_functional_type_group_count()`.
#' @param data_trait_table
#' A data frame with one row per taxon. Must contain a character
#' column (identified by `taxon_column`) holding taxon names.
#' Must have at least 4 rows and `nrow(data_trait_table)` must be
#' strictly greater than `functional_type_group_count`.
#' @param trait_dissimilarity
#' A `dist` object produced by `compute_trait_dissimilarity()`. Must
#' inherit class `"dist"`. All distance values must be finite.
#' @param hierarchical_clustering
#' An `hclust` object produced by `fit_hierarchical_clustering()`. Must inherit
#' class `"hclust"`.
#' @param functional_type_group_count
#' A single positive integer giving the number of functional-type
#' groups to cut the dendrogram at. Must be at least 2 and less
#' than `nrow(data_trait_table)`.
#' @param taxon_column
#' A single character string naming the column in `data_trait_table` that
#' contains taxon names. Default: `"taxon_name"`.
#' @param verbose
#' A single logical. If `TRUE` (default), prints the chosen
#' `functional_type_group_count` via `cli::cli_inform()`.
#' @return
#' A tibble with columns:
#' \describe{
#'   \item{taxon_name}{Taxon names (same values as
#'     `data_trait_table[[taxon_column]]`). Column name is always
#'     `"taxon_name"` regardless of `taxon_column`.}
#'   \item{functional_type}{Integer label
#'     (1..`functional_type_group_count`)
#'     giving the functional-type cluster assignment for each
#'     taxon.}
#'   \item{silhouette_width}{Per-taxon silhouette width for
#'     the chosen `functional_type_group_count` solution.}
#' }
#' @details
#' **Algorithm**:
#' \enumerate{
#'   \item Cut the dendrogram at `functional_type_group_count`
#'     via `stats::cutree()`.
#'   \item Compute per-taxon silhouette widths via
#'     `cluster::silhouette()`.
#'   \item Return a tibble of taxon names, cluster assignments,
#'     and silhouette widths.
#' }
#' Distance computation (Inf -> NA, daisy, NaN -> 1.0) and
#' hierarchical clustering are handled upstream by
#' `compute_trait_dissimilarity()` and `fit_hierarchical_clustering()` respectively.
#' FT-groups selection is handled upstream by
#' `select_functional_type_group_count()`.
#' If `nrow(data_trait_table) < 4` or
#' `functional_type_group_count >= nrow(data_trait_table)`,
#' the function aborts with an informative error.
#' @seealso [compute_trait_dissimilarity()], [fit_hierarchical_clustering()],
#'   [select_functional_type_group_count()]
#' @export
assign_functional_type_clusters <- function(
    data_trait_table,
    trait_dissimilarity,
    hierarchical_clustering,
    functional_type_group_count,
    taxon_column = "taxon_name",
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_table),
    msg = "'data_trait_table' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(taxon_column) &&
      base::length(taxon_column) == 1L,
    msg = "'taxon_column' must be a single character string."
  )

  assertthat::assert_that(
    taxon_column %in% base::colnames(data_trait_table),
    msg = stringr::str_glue(
      "'{taxon_column}' not found in 'data_trait_table'."
    )
  )

  assertthat::assert_that(
    base::inherits(trait_dissimilarity, "dist"),
    msg = "'trait_dissimilarity' must be a 'dist' object."
  )

  assertthat::assert_that(
    base::inherits(hierarchical_clustering, "hclust"),
    msg = "'hierarchical_clustering' must be an 'hclust' object."
  )

  assertthat::assert_that(
    (
      base::is.numeric(functional_type_group_count) ||
        base::is.integer(functional_type_group_count)
    ) &&
      base::length(functional_type_group_count) == 1L &&
      functional_type_group_count >= 2L,
    msg = "'functional_type_group_count' must be a single integer >= 2."
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  taxon_count <-
    base::nrow(data_trait_table)

  assertthat::assert_that(
    taxon_count >= 4L,
    msg = stringr::str_glue(
      "'data_trait_table' must have at least 4 rows (got {taxon_count})."
    )
  )

  assertthat::assert_that(
    base::as.integer(functional_type_group_count) < taxon_count,
    msg = stringr::str_glue(
      "'functional_type_group_count' ({functional_type_group_count}) ",
      "must be less than nrow(data_trait_table) ({taxon_count})."
    )
  )

  functional_type_group_count <-
    base::as.integer(functional_type_group_count)

  # Cluster assignment and silhouette widths -----
  cluster_assignments <-
    stats::cutree(
      hierarchical_clustering,
      k = functional_type_group_count
    )

  silhouette_statistics <-
    cluster::silhouette(
      cluster_assignments,
      trait_dissimilarity
    )

  if (
    base::isTRUE(verbose)
  ) {
    mean_silhouette_width <-
      base::round(
        base::mean(silhouette_statistics[, "sil_width"]),
        digits = 3L
      )

    cli::cli_inform(
      base::c(
        "i" = stringr::str_glue(
          "FT clustering: applying functional_type_group_count = ",
          "{functional_type_group_count}"
        ),
        "i" = stringr::str_glue(
          "Mean silhouette = {mean_silhouette_width}"
        )
      )
    )
  }

  data_functional_type_classification <-
    tibble::tibble(
      taxon_name = dplyr::pull(data_trait_table, taxon_column),
      functional_type = base::as.integer(cluster_assignments),
      silhouette_width = silhouette_statistics[, "sil_width"]
    )

  return(data_functional_type_classification)
}

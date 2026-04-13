#' @title Cluster Taxa into Functional Types
#' @description
#' Assigns taxa into functional types (FTs) using a pre-computed
#' Gower dissimilarity matrix, a pre-fitted hierarchical
#' clustering object, and a predetermined number of clusters `k`.
#' The number of clusters is expected to have been chosen upstream
#' (e.g. via `select_k_by_silhouette()`).
#' @param data
#' A data frame with one row per taxon. Must contain a character
#' column (identified by `taxon_col`) holding taxon names.
#' Must have at least 4 rows and `nrow(data)` must be strictly
#' greater than `k`.
#' @param dist_mat
#' A `dist` object produced by `compute_dissimilarity_matrix()`. Must
#' inherit class `"dist"`. All distance values must be finite.
#' @param hclust_obj
#' An `hclust` object produced by `fit_hclust()`. Must inherit
#' class `"hclust"`.
#' @param k
#' A single positive integer giving the number of clusters to
#' cut the dendrogram at. Must be at least 2 and less than
#' `nrow(data)`.
#' @param taxon_col
#' A single character string naming the column in `data` that
#' contains taxon names. Default: `"taxon_name"`.
#' @param verbose
#' A single logical. If `TRUE` (default), prints the chosen k
#' via `cli::cli_inform()`.
#' @return
#' A tibble with columns:
#' \describe{
#'   \item{taxon_name}{Taxon names (same values as
#'     `data[[taxon_col]]`). Column name is always
#'     `"taxon_name"` regardless of `taxon_col`.}
#'   \item{functional_type}{Integer label (1..k) giving the
#'     functional-type cluster assignment for each taxon.}
#'   \item{silhouette_width}{Per-taxon silhouette width for
#'     the chosen k solution.}
#' }
#' @details
#' **Algorithm**:
#' \enumerate{
#'   \item Cut the dendrogram at `k` via `stats::cutree()`.
#'   \item Compute per-taxon silhouette widths via
#'     `cluster::silhouette()`.
#'   \item Return a tibble of taxon names, cluster assignments,
#'     and silhouette widths.
#' }
#' Distance computation (Inf -> NA, daisy, NaN -> 1.0) and
#' hierarchical clustering are handled upstream by
#' `compute_dissimilarity_matrix()` and `fit_hclust()` respectively.
#' k-selection is handled upstream by `select_k_by_silhouette()`.
#' If `nrow(data) < 4` or `k >= nrow(data)`, the function aborts
#' with an informative error.
#' @seealso [compute_dissimilarity_matrix()], [fit_hclust()],
#'   [select_k_by_silhouette()]
#' @export
cluster_functional_types <- function(
    data,
    dist_mat,
    hclust_obj,
    k,
    taxon_col = "taxon_name",
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(taxon_col) &&
      base::length(taxon_col) == 1L,
    msg = "'taxon_col' must be a single character string."
  )

  assertthat::assert_that(
    taxon_col %in% base::colnames(data),
    msg = stringr::str_glue(
      "'{taxon_col}' not found in 'data'."
    )
  )

  assertthat::assert_that(
    base::inherits(dist_mat, "dist"),
    msg = "'dist_mat' must be a 'dist' object."
  )

  assertthat::assert_that(
    base::inherits(hclust_obj, "hclust"),
    msg = "'hclust_obj' must be an 'hclust' object."
  )

  assertthat::assert_that(
    (base::is.numeric(k) || base::is.integer(k)) &&
      base::length(k) == 1L &&
      k >= 2L,
    msg = "'k' must be a single integer >= 2."
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  n_taxa <-
    base::nrow(data)

  assertthat::assert_that(
    n_taxa >= 4L,
    msg = stringr::str_glue(
      "'data' must have at least 4 rows (got {n_taxa})."
    )
  )

  assertthat::assert_that(
    base::as.integer(k) < n_taxa,
    msg = stringr::str_glue(
      "'k' ({k}) must be less than nrow(data) ({n_taxa})."
    )
  )

  k_value <-
    base::as.integer(k)

  # Cluster assignment and silhouette widths -----
  vec_labels <-
    stats::cutree(hclust_obj, k = k_value)

  silhouette_result <-
    cluster::silhouette(vec_labels, dist_mat)

  if (
    base::isTRUE(verbose)
  ) {
    num_sil_mean <-
      base::round(
        base::mean(silhouette_result[, "sil_width"]),
        digits = 3L
      )

    cli::cli_inform(
      base::c(
        "i" = stringr::str_glue(
          "FT clustering: applying k = {k_value}"
        ),
        "i" = stringr::str_glue(
          "Mean silhouette = {num_sil_mean}"
        )
      )
    )
  }

  res <-
    tibble::tibble(
      taxon_name = dplyr::pull(data, taxon_col),
      functional_type = base::as.integer(vec_labels),
      silhouette_width = silhouette_result[, "sil_width"]
    )

  return(res)
}

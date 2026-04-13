#' @title Compute Dissimilarity Matrix from Trait Data
#' @description
#' Computes a pairwise dissimilarity matrix from a wide trait
#' table using `cluster::daisy()`. Before computation, any
#' `Inf` / `-Inf` values in numeric trait columns are replaced
#' with `NA` so that the normalisation denominator stays
#' finite. After computation, any remaining `NaN` or non-finite
#' values in the distance matrix are replaced with `1.0` (the
#' maximum dissimilarity, i.e. fully dissimilar). This function
#' isolates the distance-computation step from
#' `cluster_functional_types()` so that the distance matrix can
#' be stored as an independent, inspectable pipeline target.
#' @param data
#' A data frame with one row per taxon. Must contain a column
#' identified by `taxon_col` and at least one additional trait
#' column. `NA` values in trait columns are handled natively by
#' `cluster::daisy()`.
#' @param taxon_col
#' A single character string naming the column that holds taxon
#' names. Default: `"taxon_name"`. This column is excluded before
#' the distance computation.
#' @param metric
#' A single character string passed to `cluster::daisy()` as the
#' `metric` argument. Default: `"gower"`. Other valid values are
#' `"euclidean"` and `"manhattan"` (see `?cluster::daisy`).
#' @return
#' An object of class `"dist"` (as returned by `stats::as.dist()`)
#' with one entry per pair of taxa. All values are in [0, 1] when
#' `metric = "gower"` (Gower default).
#' @details
#' **Steps performed**:
#' \enumerate{
#'   \item Select all columns except `taxon_col` as trait columns.
#'   \item Replace any `Inf` / `-Inf` values in numeric trait
#'     columns with `NA` via `dplyr::if_else()`.
#'   \item Compute `cluster::daisy(metric = metric)`.
#'   \item If any value in the resulting distance vector is
#'     non-finite (e.g. `NaN` arising when two taxa share no
#'     non-`NA` trait), replace it with `1.0` and reconvert via
#'     `stats::as.dist()`.
#' }
#' @seealso [fit_hclust()], [cluster_functional_types()]
#' @export
compute_dissimilarity_matrix <- function(
    data,
    taxon_col = "taxon_name",
    metric = "gower") {
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
    base::is.character(metric) &&
      base::length(metric) == 1L,
    msg = "'metric' must be a single character string."
  )

  vec_trait_cols <-
    base::setdiff(base::colnames(data), taxon_col)

  assertthat::assert_that(
    base::length(vec_trait_cols) >= 1L,
    msg = "No trait columns found in 'data'."
  )

  data_traits_only <-
    dplyr::select(data, dplyr::all_of(vec_trait_cols)) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(base::is.numeric),
        ~ dplyr::if_else(base::is.infinite(.x), NA_real_, .x)
      )
    )

  res_dist <-
    cluster::daisy(
      data_traits_only,
      metric = metric
    )

  vec_dist_vals <-
    base::as.numeric(res_dist)

  if (
    base::any(
      !base::is.finite(vec_dist_vals)
    )
  ) {
    dist_mat <-
      base::as.matrix(res_dist)

    dist_mat[!base::is.finite(dist_mat)] <- 1.0

    res_dist <-
      stats::as.dist(dist_mat)
  }

  return(res_dist)
}

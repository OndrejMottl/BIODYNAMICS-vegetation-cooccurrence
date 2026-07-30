#' @title Compute Trait Dissimilarity
#' @description
#' Computes a pairwise dissimilarity matrix from a wide trait
#' table using `cluster::daisy()`. Before computation, any
#' `Inf` / `-Inf` values in numeric trait columns are replaced
#' with `NA` so that the normalisation denominator stays
#' finite. After computation, any remaining `NaN` or non-finite
#' values in the distance matrix are replaced with `1.0` (the
#' maximum dissimilarity, i.e. fully dissimilar). This function
#' isolates the distance-computation step from
#' functional-type clustering so that the distance matrix can
#' be stored as an independent, inspectable pipeline target.
#' @param data_trait_table
#' A data frame with one row per taxon. Must contain a column
#' identified by `taxon_column` and at least one additional trait
#' column. `NA` values in trait columns are handled natively by
#' `cluster::daisy()`.
#' @param taxon_column
#' A single character string naming the column that holds taxon
#' names. Default: `"taxon_name"`. This column is excluded before
#' the distance computation.
#' @param distance_metric
#' A single character string passed to `cluster::daisy()` as the
#' `metric` argument. Default: `"gower"`. Other valid values are
#' `"euclidean"` and `"manhattan"` (see `?cluster::daisy`).
#' @return
#' An object of class `"dist"` (as returned by `stats::as.dist()`)
#' with one entry per pair of taxa. All values are in [0, 1] when
#' `distance_metric = "gower"` (Gower default).
#' @details
#' **Steps performed**:
#' \enumerate{
#'   \item Select all columns except `taxon_column` as trait columns.
#'   \item Replace any `Inf` / `-Inf` values in numeric trait
#'     columns with `NA` via `dplyr::if_else()`.
#'   \item Compute `cluster::daisy(metric = distance_metric)`.
#'   \item If any value in the resulting distance vector is
#'     non-finite (e.g. `NaN` arising when two taxa share no
#'     non-`NA` trait), replace it with `1.0` and reconvert via
#'     `stats::as.dist()`.
#' }
#' @seealso [fit_hierarchical_clustering()], [assign_functional_type_clusters()]
#' @export
compute_trait_dissimilarity <- function(
    data_trait_table,
    taxon_column = "taxon_name",
    distance_metric = "gower") {
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
    base::is.character(distance_metric) &&
      base::length(distance_metric) == 1L,
    msg = "'distance_metric' must be a single character string."
  )

  trait_columns <-
    base::setdiff(base::colnames(data_trait_table), taxon_column)

  assertthat::assert_that(
    base::length(trait_columns) >= 1L,
    msg = "No trait columns found in 'data_trait_table'."
  )

  data_trait_matrix <-
    data_trait_table |>
    dplyr::select(
      dplyr::all_of(base::c(taxon_column, trait_columns))
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(base::is.numeric),
        .fns = ~ dplyr::if_else(
          base::is.infinite(.x),
          NA_real_,
          .x
        )
      )
    ) |>
    tibble::column_to_rownames(var = taxon_column)

  trait_dissimilarity <-
    cluster::daisy(
      data_trait_matrix,
      metric = distance_metric
    )

  dissimilarity_values <-
    base::as.numeric(trait_dissimilarity)

  if (
    base::any(
      !base::is.finite(dissimilarity_values)
    )
  ) {
    dissimilarity_matrix <-
      base::as.matrix(trait_dissimilarity)

    dissimilarity_matrix[
      !base::is.finite(dissimilarity_matrix)
    ] <- 1.0

    trait_dissimilarity <-
      stats::as.dist(dissimilarity_matrix)
  }

  return(trait_dissimilarity)
}

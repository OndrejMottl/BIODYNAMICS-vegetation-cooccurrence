#' @title Cluster Taxa into Functional Types
#' @description
#' Clusters taxa into functional types (FTs) using Gower distance on
#' a wide trait table and Ward D2 hierarchical clustering. The number
#' of clusters k is chosen automatically by maximising the average
#' silhouette width over k = 2 .. `k_max`.
#' @param data
#' A data frame with one row per taxon. Must contain a character
#' column (identified by `taxon_col`) holding taxon names and at
#' least one numeric trait column. `NA` values in trait columns are
#' handled by Gower distance computation.
#' @param taxon_col
#' A single character string naming the column in `data` that
#' contains taxon names. Default: `"taxon_name"`.
#' @param k_max
#' A single positive integer giving the maximum number of clusters
#' to evaluate. Must be at least 2 and at most `nrow(data) - 1`.
#' Default: `10L`.
#' @param metric
#' A single character string passed to `cluster::daisy()` as the
#' `metric` argument. Default: `"gower"`. Other valid values are
#' `"euclidean"` and `"manhattan"` (see `?cluster::daisy`).
#' @param method
#' A single character string passed to `stats::hclust()` as the
#' `method` argument. Default: `"ward.D2"`. See `?stats::hclust`
#' for all valid linkage methods.
#' @param verbose
#' A single logical. If `TRUE` (default), prints the chosen k and
#' a summary of silhouette widths via `cli::cli_inform()`.
#' @return
#' A tibble with columns:
#' \describe{
#'   \item{taxon_name}{Taxon names (same values as `data[[taxon_col]]`).
#'     Column name is always `"taxon_name"` regardless of `taxon_col`.
#'   }
#'   \item{functional_type}{Integer label (1..k_chosen) giving the
#'     functional-type cluster assignment for each taxon.}
#'   \item{silhouette_width}{Per-taxon silhouette width for the
#'     chosen k solution.}
#' }
#' The attribute `k_chosen` (a single integer) is attached to the
#' returned tibble.
#' @details
#' **Algorithm**:
#' \enumerate{
#'   \item Replace any `Inf` / `-Inf` values in trait columns with `NA`
#'     so that one taxon's out-of-range measurement does not propagate
#'     infinity through the Gower normalisation denominator.
#'   \item Compute a dissimilarity matrix from all non-taxon columns
#'     via `cluster::daisy(metric = metric)`. The default `"gower"`
#'     metric handles `NA` values and mixed numeric/categorical
#'     traits without pre-processing.
#'   \item Replace any remaining `NaN` or non-finite values in the
#'     Gower distance matrix with `1.0` (maximum Gower distance,
#'     i.e. fully dissimilar). Such values can arise when two taxa
#'     share no measured trait at all (both have `NA` for every shared
#'     trait), yet both individually pass the all-NA row filter.
#'   \item Hierarchical clustering via
#'     `stats::hclust(method = method)`.
#'   \item Cut the dendrogram at k = 2 .. `k_max` and compute the
#'     average silhouette width for each k via
#'     `cluster::silhouette()`. Select k that maximises the
#'     average silhouette width.
#'   \item Return the cluster assignments and per-taxon silhouette
#'     widths for the chosen k.
#' }
#' If `nrow(data) < 4` or `k_max` is reduced to fewer than 2 valid
#' values, the function aborts with an informative error.
#' @seealso [get_functional_type_classification()]
#' @export
cluster_functional_types <- function(
    data,
    taxon_col = "taxon_name",
    k_max = 10L,
    metric = "gower",
    method = "ward.D2",
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
    (base::is.numeric(k_max) || base::is.integer(k_max)) &&
      base::length(k_max) == 1L &&
      k_max >= 2L,
    msg = "'k_max' must be a single integer >= 2."
  )

  assertthat::assert_that(
    base::is.character(metric) &&
      base::length(metric) == 1L,
    msg = "'metric' must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(method) &&
      base::length(method) == 1L,
    msg = "'method' must be a single character string."
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  vec_trait_cols <-
    base::setdiff(base::colnames(data), taxon_col)

  assertthat::assert_that(
    base::length(vec_trait_cols) >= 1L,
    msg = "No trait columns found in 'data'."
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
    base::as.integer(k_max) < n_taxa,
    msg = stringr::str_glue(
      "'k_max' ({k_max}) must be less than nrow(data) ({n_taxa})."
    )
  )

  k_max_valid <-
    base::as.integer(k_max)

  # Compute distance -----
  data_traits_only <-
    dplyr::select(data, dplyr::all_of(vec_trait_cols)) |>
    dplyr::mutate(
      # Replace Inf/-Inf with NA so the Gower range denominator stays
      # finite; daisy(Gower) handles NA natively but not Inf.
      dplyr::across(
        dplyr::where(base::is.numeric),
        ~ dplyr::if_else(base::is.infinite(.x), NA_real_, .x)
      )
    )

  dist_gower <-
    cluster::daisy(
      data_traits_only,
      metric = metric
    )

  # Replace NaN/non-finite values with 1.0 (maximum Gower distance).
  # NaN arises when two taxa share no valid (non-NA) trait at all;
  # hclust() crashes on non-finite distances.
  vec_dist_vals <-
    base::as.numeric(dist_gower)

  if (base::any(!base::is.finite(vec_dist_vals))) {
    dist_mat <-
      base::as.matrix(dist_gower)
    dist_mat[!base::is.finite(dist_mat)] <- 1.0
    dist_gower <-
      stats::as.dist(dist_mat)
  }

  # Hierarchical clustering -----
  hclust_obj <-
    stats::hclust(
      dist_gower,
      method = method
    )

  # k selection via silhouette -----
  vec_k <-
    base::seq(2L, k_max_valid)

  vec_sil_avg <-
    vec_k |>
    purrr::map_dbl(
      .f = ~ {
        vec_cut <-
          stats::cutree(hclust_obj, k = .x)

        sil_obj <-
          cluster::silhouette(vec_cut, dist_gower)

        base::mean(sil_obj[, "sil_width"])
      }
    )

  k_chosen <-
    vec_k[base::which.max(vec_sil_avg)]

  # Final cluster assignment and silhouette widths -----
  vec_labels <-
    stats::cutree(hclust_obj, k = k_chosen)

  sil_final <-
    cluster::silhouette(vec_labels, dist_gower)

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      base::c(
        "i" = stringr::str_glue(
          "FT clustering: chose k = {k_chosen} ",
          "(from k = 2..{k_max_valid})"
        ),
        "i" = stringr::str_glue(
          "Mean silhouette = ",
          "{base::round(base::max(vec_sil_avg), 3)}"
        )
      )
    )
  }

  res <-
    tibble::tibble(
      taxon_name = dplyr::pull(data, taxon_col),
      functional_type = base::as.integer(vec_labels),
      silhouette_width = sil_final[, "sil_width"]
    )

  base::attr(res, "k_chosen") <-
    k_chosen

  return(res)
}

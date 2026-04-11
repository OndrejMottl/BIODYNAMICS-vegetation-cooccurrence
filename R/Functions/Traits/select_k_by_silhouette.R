#' @title Select Optimal k via Average Silhouette Width
#' @description
#' Sweeps k = 2 .. `k_max`, cuts the dendrogram at each k, and
#' returns the k that maximises the average silhouette width
#' computed from `dist_gower`.
#' @param dist_gower
#' A `dist` object produced by `compute_gower_distance()`. Must
#' inherit class `"dist"`.
#' @param hclust_obj
#' An `hclust` object produced by `fit_hclust()`. Must inherit
#' class `"hclust"`.
#' @param k_max
#' A single positive integer giving the maximum number of clusters
#' to evaluate. Must be at least 2. If `k_max` is greater than or
#' equal to the number of observations, it is silently clamped to
#' `n_observations - 1L`. Default: `10L`.
#' @return
#' A single integer giving the optimal number of clusters (>= 2).
#' @details
#' For each k in 2..`k_max` the function calls
#' `stats::cutree()` followed by `cluster::silhouette()` and
#' records the mean silhouette width. The k with the highest mean
#' is returned. Ties are broken by `base::which.max()` (first
#' occurrence).
#' @seealso [compute_gower_distance()], [fit_hclust()],
#'   [cluster_functional_types()]
#' @export
select_k_by_silhouette <- function(
    dist_gower,
    hclust_obj,
    k_max = 10L) {
  assertthat::assert_that(
    base::inherits(dist_gower, "dist"),
    msg = "'dist_gower' must be a 'dist' object."
  )

  assertthat::assert_that(
    base::inherits(hclust_obj, "hclust"),
    msg = "'hclust_obj' must be an 'hclust' object."
  )

  assertthat::assert_that(
    (base::is.numeric(k_max) || base::is.integer(k_max)) &&
      base::length(k_max) == 1L &&
      k_max >= 2L,
    msg = "'k_max' must be a single integer >= 2."
  )

  n_observations <-
    base::length(hclust_obj$order)

  k_max <-
    base::min(
      base::as.integer(k_max),
      n_observations - 1L
    )

  vec_k <-
    base::seq(2L, base::as.integer(k_max))

  vec_silhouette_mean <-
    vec_k |>
    purrr::map_dbl(
      .f = ~ {
        vec_cut <-
          stats::cutree(hclust_obj, k = .x)

        silhouette_obj <-
          cluster::silhouette(vec_cut, dist_gower)

        base::mean(silhouette_obj[, "sil_width"])
      }
    )

  res <-
    vec_k[base::which.max(vec_silhouette_mean)]

  return(res)
}

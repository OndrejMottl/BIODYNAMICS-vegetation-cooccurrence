#' @title Select Optimal Number of Functional-Type Groups via Average Silhouette Width
#' @description
#' Sweeps `number_of_ft_groups` = `ft_groups_min` .. `ft_groups_max`,
#' cuts the dendrogram at each value, and returns the
#' `number_of_ft_groups` that maximises the average silhouette width
#' computed from `dist_mat`.
#' @param dist_mat
#' A `dist` object produced by `compute_dissimilarity_matrix()`. Must
#' inherit class `"dist"`.
#' @param hclust_obj
#' An `hclust` object produced by `fit_hclust()`. Must inherit
#' class `"hclust"`.
#' @param ft_groups_min
#' A single positive integer giving the minimum number of
#' functional-type groups to evaluate. Must be at least 2 and no
#' greater than `ft_groups_max`. Default: `10L`.
#' @param ft_groups_max
#' A single positive integer giving the maximum number of
#' functional-type groups to evaluate. Must be at least 2. If
#' `ft_groups_max` is greater than or equal to the number of
#' observations, it is silently clamped to `n_observations - 1L`.
#' After clamping `ft_groups_max`, `ft_groups_min` is silently
#' clamped to `min(ft_groups_min, ft_groups_max)` to handle
#' datasets with very few taxa without erroring. Default: `25L`.
#' @return
#' A single integer giving the optimal number of functional-type
#' groups (>= `ft_groups_min` after clamping).
#' @details
#' For each `number_of_ft_groups` in `ft_groups_min`..`ft_groups_max`
#' the function calls `stats::cutree()` followed by
#' `cluster::silhouette()` and records the mean silhouette width.
#' The `number_of_ft_groups` with the highest mean is returned.
#' Ties are broken by `base::which.max()` (first occurrence).
#' @seealso [compute_dissimilarity_matrix()], [fit_hclust()],
#'   [cluster_functional_types()]
#' @export
select_ft_groups_by_silhouette <- function(
    dist_mat,
    hclust_obj,
    ft_groups_min = 10L,
    ft_groups_max = 25L) {
  assertthat::assert_that(
    base::inherits(dist_mat, "dist"),
    msg = "'dist_mat' must be a 'dist' object."
  )

  assertthat::assert_that(
    base::inherits(hclust_obj, "hclust"),
    msg = "'hclust_obj' must be an 'hclust' object."
  )

  assertthat::assert_that(
    (base::is.numeric(ft_groups_max) || base::is.integer(ft_groups_max)) &&
      base::length(ft_groups_max) == 1L &&
      ft_groups_max >= 2L,
    msg = "'ft_groups_max' must be a single integer >= 2."
  )

  assertthat::assert_that(
    (base::is.numeric(ft_groups_min) || base::is.integer(ft_groups_min)) &&
      base::length(ft_groups_min) == 1L &&
      ft_groups_min >= 2L,
    msg = "'ft_groups_min' must be a single integer >= 2."
  )

  assertthat::assert_that(
    ft_groups_min <= ft_groups_max,
    msg = stringr::str_glue(
      "'ft_groups_min' ({ft_groups_min}) must not exceed",
      " 'ft_groups_max' ({ft_groups_max})."
    )
  )

  n_observations <-
    purrr::chuck(hclust_obj, "order") |>
    base::length()

  ft_groups_max_clamped <-
    base::min(
      base::as.integer(ft_groups_max),
      n_observations - 1L
    )

  ft_groups_min_clamped <-
    base::min(
      base::as.integer(ft_groups_min),
      ft_groups_max_clamped
    )

  vec_groups <-
    base::seq(ft_groups_min_clamped, ft_groups_max_clamped)

  vec_silhouette_mean <-
    vec_groups |>
    purrr::map_dbl(
      .f = ~ {
        vec_cut <-
          stats::cutree(hclust_obj, k = .x)

        silhouette_obj <-
          cluster::silhouette(vec_cut, dist_mat)

        base::mean(silhouette_obj[, "sil_width"])
      }
    )

  res <-
    vec_groups[base::which.max(vec_silhouette_mean)]

  return(res)
}

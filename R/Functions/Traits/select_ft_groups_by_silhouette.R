#' @title Select Optimal Number of Functional-Type Groups via
#'   Average Silhouette Width
#' @description
#' Sweeps `number_of_ft_groups` = `ft_groups_min` ..
#' `ft_groups_max`, cuts the dendrogram at each value, and
#' returns the `number_of_ft_groups` that maximises the average
#' silhouette width computed from `dist_mat`.
#'
#' When `data_community`, `minimal_proportion`, and `min_n_taxa`
#' are all supplied, only `k` values that produce at least
#' `min_n_taxa` non-constant FT columns (after simulated
#' binarization against `data_community`) are considered. Among
#' viable candidates the highest-silhouette `k` is returned. If
#' no `k` is viable a warning is issued and the `k` with the
#' maximum number of non-constant groups is returned instead.
#' @param dist_mat
#' A `dist` object produced by `compute_dissimilarity_matrix()`.
#' Must inherit class `"dist"`.
#' @param hclust_obj
#' An `hclust` object produced by `fit_hclust()`. Must inherit
#' class `"hclust"`.
#' @param ft_groups_min
#' A single positive integer giving the minimum number of
#' functional-type groups to evaluate. Must be at least 2 and
#' no greater than `ft_groups_max`. Default: `10L`.
#' @param ft_groups_max
#' A single positive integer giving the maximum number of
#' functional-type groups to evaluate. Must be at least 2. If
#' `ft_groups_max` is greater than or equal to the number of
#' observations, it is silently clamped to
#' `n_observations - 1L`. After clamping `ft_groups_max`,
#' `ft_groups_min` is silently clamped to
#' `min(ft_groups_min, ft_groups_max)` to handle datasets with
#' very few taxa without erroring. Default: `25L`.
#' @param data_community
#' Optional. A long-format data frame with columns
#' `taxon`, `dataset_name`, `age`, and `pollen_prop`, as
#' produced by `classify_to_functional_type()` or
#' `classify_taxonomic_resolution()`. When supplied together
#' with `minimal_proportion` and `min_n_taxa`, enables
#' viability-aware selection. Default: `NULL`.
#' @param minimal_proportion
#' Optional. A single numeric value in (0, 1). A sample is
#' considered to contain an FT group when the summed
#' `pollen_prop` for that group exceeds this threshold. Must
#' be supplied when `data_community` is not `NULL`. Default:
#' `NULL`.
#' @param min_n_taxa
#' Optional. A single positive integer. The minimum number of
#' non-constant FT columns (i.e. groups present in strictly
#' between 0 % and 100 % of samples after binarization at
#' `minimal_proportion`) that a candidate `k` must produce to
#' be considered viable. Must be supplied when `data_community`
#' is not `NULL`. Default: `NULL`.
#' @return
#' A single integer giving the optimal number of functional-type
#' groups (>= `ft_groups_min` after clamping).
#' @details
#' For each `number_of_ft_groups` in
#' `ft_groups_min`..`ft_groups_max` the function calls
#' `stats::cutree()` followed by `cluster::silhouette()` and
#' records the mean silhouette width.
#'
#' When viability checking is active (`data_community` is not
#' `NULL`), the dendrogram cut is also joined to
#' `data_community` to compute each FT group's presence rate
#' across samples. A group is non-constant when
#' `0 < pct_present < 1`. The count of non-constant groups
#' is recorded as `n_non_constant`.
#'
#' Selection proceeds as follows:
#' \enumerate{
#'   \item If viability checking is inactive: return
#'     `which.max(silhouette)` (original behaviour).
#'   \item If at least one `k` has `n_non_constant >= min_n_taxa`:
#'     return the highest-silhouette among those `k` values.
#'   \item If no `k` is viable: emit a `cli::cli_warn()` and
#'     return the `k` with the maximum `n_non_constant`.
#' }
#'
#' Ties are broken by `base::which.max()` (first occurrence).
#' @seealso [compute_dissimilarity_matrix()], [fit_hclust()],
#'   [cluster_functional_types()]
#' @export
select_ft_groups_by_silhouette <- function(
    dist_mat,
    hclust_obj,
    ft_groups_min = 10L,
    ft_groups_max = 25L,
    data_community = NULL,
    minimal_proportion = NULL,
    min_n_taxa = NULL) {
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

  assertthat::assert_that(
    base::is.null(data_community) || base::is.data.frame(data_community),
    msg = "'data_community' must be NULL or a data frame."
  )

  assertthat::assert_that(
    base::is.null(data_community) ||
      base::all(
        base::c(
          "taxon", "dataset_name", "age", "pollen_prop"
        ) %in%
          base::colnames(data_community)
      ),
    msg = stringr::str_c(
      "'data_community' must contain columns: ",
      "taxon, dataset_name, age, pollen_prop."
    )
  )

  assertthat::assert_that(
    base::is.null(data_community) || !base::is.null(minimal_proportion),
    msg = stringr::str_c(
      "'minimal_proportion' must be supplied",
      " when 'data_community' is not NULL."
    )
  )

  assertthat::assert_that(
    base::is.null(data_community) || !base::is.null(min_n_taxa),
    msg = stringr::str_c(
      "'min_n_taxa' must be supplied",
      " when 'data_community' is not NULL."
    )
  )

  assertthat::assert_that(
    base::is.null(minimal_proportion) || (
      base::is.numeric(minimal_proportion) &&
        base::length(minimal_proportion) == 1L &&
        minimal_proportion > 0 &&
        minimal_proportion < 1
    ),
    msg = "'minimal_proportion' must be a single numeric in (0, 1)."
  )

  assertthat::assert_that(
    base::is.null(min_n_taxa) || (
      (base::is.numeric(min_n_taxa) || base::is.integer(min_n_taxa)) &&
        base::length(min_n_taxa) == 1L &&
        min_n_taxa >= 1L
    ),
    msg = "'min_n_taxa' must be a single positive integer."
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

  # Simple case: no viability constraint — return the global silhouette maximum
  if (
    base::is.null(data_community)
  ) {
    res <-
      vec_groups[
        base::which.max(vec_silhouette_mean)
      ]

    return(res)
  }

  # Viability-aware path: count non-constant FT groups for each candidate k
  vec_n_non_constant <-
    vec_groups |>
    purrr::map_int(
      .f = ~ {
        vec_cut <-
          stats::cutree(hclust_obj, k = .x)

        data_cut <-
          tibble::tibble(
            taxon = base::names(vec_cut),
            ft_group = base::as.character(
              base::unname(vec_cut)
            )
          )

        data_community |>
          dplyr::inner_join(
            data_cut,
            by = dplyr::join_by(taxon)
          ) |>
          dplyr::group_by(
            .data$dataset_name,
            .data$age,
            .data$ft_group
          ) |>
          dplyr::summarise(
            sum_prop = base::sum(
              .data$pollen_prop,
              na.rm = TRUE
            ),
            .groups = "drop"
          ) |>
          dplyr::mutate(
            present = .data$sum_prop > minimal_proportion
          ) |>
          dplyr::group_by(.data$ft_group) |>
          dplyr::summarise(
            pct_present = base::mean(
              .data$present,
              na.rm = TRUE
            ),
            .groups = "drop"
          ) |>
          dplyr::filter(
            .data$pct_present > 0 &
              .data$pct_present < 1
          ) |>
          base::nrow() |>
          base::as.integer()
      }
    )

  vec_viable <-
    base::which(vec_n_non_constant >= min_n_taxa)

  # Fallback: no viable k found — warn and return the k with the most
  # non-constant groups as a best-effort result
  if (
    base::length(vec_viable) == 0L
  ) {
    cli::cli_warn(
      base::c(
        "!" = stringr::str_glue(
          "No viable k in {ft_groups_min_clamped}..",
          "{ft_groups_max_clamped} produces >=",
          " {min_n_taxa} non-constant FT groups after",
          " binarization. Returning k with max",
          " non-constant groups."
        )
      )
    )

    return(vec_groups[base::which.max(vec_n_non_constant)])
  }

  # Happy path: return the highest-silhouette k among viable candidates
  res <-
    vec_groups[
      vec_viable[
        base::which.max(
          vec_silhouette_mean[vec_viable]
        )
      ]
    ]

  return(res)
}

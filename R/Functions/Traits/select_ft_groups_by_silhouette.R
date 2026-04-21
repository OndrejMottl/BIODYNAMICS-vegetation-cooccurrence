#' @title Select Optimal Number of Functional-Type Groups via
#'   Average Silhouette Width
#' @description
#' Sweeps `number_of_ft_groups` = `ft_groups_min` ..
#' `ft_groups_max`, cuts the dendrogram at each value, and
#' returns the `number_of_ft_groups` that maximises the average
#' silhouette width computed from `dist_mat`.
#'
#' The function also simulates the downstream pipeline filter
#' chain for each candidate `k` and only considers values that
#' leave at least `min_n_taxa` non-constant FT columns. The
#' filter chain applied is: `filter_rare_taxa()`,
#' `filter_community_by_n_cores()`, `filter_by_n_samples()`,
#' `prepare_community_for_fit()`, optionally
#' `binarize_community_data()` (when `error_family` is
#' `"binomial"`), and `filter_constant_taxa()`. The number of
#' surviving columns is compared to `min_n_taxa`. Among viable
#' candidates the highest-silhouette `k` is returned. If no
#' `k` is viable an error is raised via `cli::cli_abort()`.
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
#' A long-format data frame with columns `taxon`,
#' `dataset_name`, `age`, and `pollen_prop`, as produced by
#' `classify_to_functional_type()` or
#' `classify_taxonomic_resolution()`. Used to run the
#' viability filter chain for each candidate `k`.
#' @param minimal_proportion
#' A single numeric value in (0, 1). A sample is considered
#' to contain an FT group when the summed `pollen_prop` for
#' that group exceeds this threshold.
#' @param min_n_taxa
#' A single positive integer. The minimum number of
#' non-constant FT columns (i.e. groups present in strictly
#' between 0 % and 100 % of samples after binarization at
#' `minimal_proportion`) that a candidate `k` must produce to
#' be considered viable.
#' @param min_n_cores
#' A single positive integer. Forwarded to
#' `filter_community_by_n_cores()` during the viability check
#' to remove FT groups present in fewer than this many
#' distinct cores (`dataset_name` values).
#' @param min_n_samples
#' A single positive integer. Forwarded to
#' `filter_by_n_samples()` during the viability check to
#' remove FT groups present in fewer than this many distinct
#' spatio-temporal samples (`(dataset_name, age)`
#' combinations).
#' @param error_family
#' A single character string (e.g. `"binomial"`). When
#' `"binomial"`, `binarize_community_data()` is applied to
#' the wide community matrix before `filter_constant_taxa()`
#' during the viability check, mirroring the pipeline step.
#' @return
#' A single integer giving the optimal number of functional-type
#' groups (>= `ft_groups_min` after clamping).
#' @details
#' For each `number_of_ft_groups` in
#' `ft_groups_min`..`ft_groups_max` the function calls
#' `stats::cutree()` followed by `cluster::silhouette()` and
#' records the mean silhouette width.
#'
#' For each candidate `k` the community data are aggregated
#' to the FT level (summed `pollen_prop` per
#' `(dataset_name, age, ft_group)`) and then passed through
#' the actual pipeline filter chain in sequence:
#' \enumerate{
#'   \item `filter_rare_taxa()` at `minimal_proportion`.
#'   \item `filter_community_by_n_cores()`.
#'   \item `filter_by_n_samples()`.
#'   \item `prepare_community_for_fit()` (wide matrix,
#'     using all surviving samples as their own IDs).
#'   \item `binarize_community_data()` if
#'     `error_family == "binomial"`.
#'   \item `filter_constant_taxa()`.
#' }
#' The number of surviving columns is the viability count. If
#' any step errors (e.g. all taxa removed), the count is
#' treated as zero.
#'
#' Selection proceeds as follows:
#' \enumerate{
#'   \item If at least one `k` has viability count >=
#'     `min_n_taxa`: return the highest-silhouette among
#'     those `k` values.
#'   \item If no `k` is viable: abort with `cli::cli_abort()`.
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
    data_community,
    minimal_proportion,
    min_n_taxa,
    min_n_cores,
    min_n_samples,
    error_family) {
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
    base::is.data.frame(data_community),
    msg = "'data_community' must be a data frame."
  )

  assertthat::assert_that(
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
    base::is.numeric(minimal_proportion) &&
      base::length(minimal_proportion) == 1L &&
      minimal_proportion > 0 &&
      minimal_proportion < 1,
    msg = "'minimal_proportion' must be a single numeric in (0, 1)."
  )

  assertthat::assert_that(
    (base::is.numeric(min_n_taxa) || base::is.integer(min_n_taxa)) &&
      base::length(min_n_taxa) == 1L &&
      min_n_taxa >= 1L,
    msg = "'min_n_taxa' must be a single positive integer."
  )

  assertthat::assert_that(
    (base::is.numeric(min_n_cores) || base::is.integer(min_n_cores)) &&
      base::length(min_n_cores) == 1L &&
      min_n_cores >= 1L,
    msg = "'min_n_cores' must be a single positive integer."
  )

  assertthat::assert_that(
    (base::is.numeric(min_n_samples) || base::is.integer(min_n_samples)) &&
      base::length(min_n_samples) == 1L &&
      min_n_samples >= 1L,
    msg = "'min_n_samples' must be a single positive integer."
  )

  assertthat::assert_that(
    base::is.character(error_family) &&
      base::length(error_family) == 1L,
    msg = "'error_family' must be a single character string."
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

  # Run the downstream filter chain for each candidate k to check viability.
  # Count the surviving non-constant FT group columns.
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

        # Aggregate community data to the FT level, mirroring
        # classify_to_functional_type(): sum pollen_prop per
        # (dataset_name, age, ft_group).
        data_ft_community <-
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
            pollen_prop = base::sum(
              .data$pollen_prop,
              na.rm = TRUE
            ),
            .groups = "drop"
          ) |>
          dplyr::rename(taxon = "ft_group")

        # Run the actual pipeline filter chain.
        # Return 0L if any step removes all taxa.
        base::tryCatch(
          {
            data_ft_community <-
              filter_rare_taxa(
                data = data_ft_community,
                minimal_proportion = minimal_proportion
              )

            data_ft_community <-
              filter_community_by_n_cores(
                data = data_ft_community,
                min_n_cores = min_n_cores
              )

            data_ft_community <-
              filter_by_n_samples(
                data = data_ft_community,
                min_n_samples = min_n_samples
              )

            data_sample_ids <-
              data_ft_community |>
              dplyr::distinct(
                .data$dataset_name,
                .data$age
              )

            data_matrix <-
              prepare_community_for_fit(
                data_community_long = data_ft_community,
                data_sample_ids = data_sample_ids
              )

            if (error_family == "binomial") {
              data_matrix <-
                binarize_community_data(
                  data_community_matrix = data_matrix
                )
            }

            data_matrix <-
              filter_constant_taxa(
                data_community_matrix = data_matrix
              )

            base::ncol(data_matrix) |>
              base::as.integer()
          },
          error = function(e) 0L
        )
      }
    )

  vec_is_viable <-
    (vec_n_non_constant >= min_n_taxa)

  if (
    !base::any(vec_is_viable)
    ) {
    cli::cli_abort(
      base::c(
        "x" = stringr::str_glue(
          "No viable k in {ft_groups_min_clamped}..",
          "{ft_groups_max_clamped} produces >=",
          " {min_n_taxa} non-constant FT groups after",
          " the pipeline filter chain."
        )
      )
    )
  }

  # Happy path: return the highest-silhouette k among viable candidates
  res_optimal_k <-
    vec_groups[vec_is_viable][
      base::which.max(
        vec_silhouette_mean[vec_is_viable]
      )
    ]

  return(res_optimal_k)
}

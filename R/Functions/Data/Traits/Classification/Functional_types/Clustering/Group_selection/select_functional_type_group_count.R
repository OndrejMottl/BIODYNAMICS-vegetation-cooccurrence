#' @title Select Functional-Type Group Count
#' @description
#' Sweeps `functional_type_group_count_min` ..
#' `functional_type_group_count_max`, cuts the dendrogram at each value,
#' and returns the group count that maximises the average
#' silhouette width computed from `trait_dissimilarity`.
#'
#' The function also simulates the downstream pipeline filter
#' chain for each candidate `k` and only considers values that
#' leave at least `minimum_taxon_count` non-constant FT columns. The
#' filter chain applied is: `filter_community_by_minimum_proportion()`,
#' `filter_community_by_minimum_core_count()`,
#' `filter_community_by_minimum_sample_count()`,
#' `prepare_community_for_fit()`, optionally
#' `compute_community_presence_absence()` (when `error_family` is
#' `"binomial"`), and `filter_constant_taxa()`. The number of
#' surviving columns is compared to `minimum_taxon_count`. Among viable
#' candidates the highest-silhouette `k` is returned. If no
#' `k` is viable an error is raised via `cli::cli_abort()`.
#' @param trait_dissimilarity
#' A `dist` object produced by `compute_trait_dissimilarity()`.
#' Must inherit class `"dist"`.
#' @param hierarchical_clustering
#' An `hclust` object produced by `fit_hierarchical_clustering()`. Must inherit
#' class `"hclust"`.
#' @param functional_type_group_count_min
#' A single positive integer giving the minimum number of
#' functional-type groups to evaluate. Must be at least 2 and
#' no greater than `functional_type_group_count_max`. Default: `10L`.
#' @param functional_type_group_count_max
#' A single positive integer giving the maximum number of
#' functional-type groups to evaluate. Must be at least 2. If
#' `functional_type_group_count_max` is greater than or equal to the number of
#' observations, it is silently clamped to
#' `n_observations - 1L`. After clamping the maximum,
#' `functional_type_group_count_min` is silently clamped to
#' the adjusted maximum to handle datasets with
#' very few taxa without erroring. Default: `25L`.
#' @param data_community
#' A long-format data frame with columns `taxon`,
#' `dataset_name`, `age`, and `value`, as produced by
#' `classify_to_functional_type()` or
#' `classify_taxonomic_resolution()`. Used to run the
#' viability filter chain for each candidate `k`.
#' @param minimum_proportion
#' A single numeric value in (0, 1). A sample is considered
#' to contain an FT group when the summed `value` for
#' that group exceeds this threshold.
#' @param minimum_taxon_count
#' A single positive integer. The minimum number of
#' non-constant FT columns (i.e. groups present in strictly
#' between 0 % and 100 % of samples after binarization at
#' `minimum_proportion`) that a candidate `k` must produce to
#' be considered viable.
#' @param minimum_core_count
#' A single positive integer. Forwarded to
#' `filter_community_by_minimum_core_count()` during the viability check
#' to remove FT groups present in fewer than this many
#' distinct cores (`dataset_name` values).
#' @param minimum_sample_count
#' A single positive integer. Forwarded to
#' `filter_community_by_minimum_sample_count()` during the viability check to
#' remove FT groups present in fewer than this many distinct
#' spatio-temporal samples (`(dataset_name, age)`
#' combinations).
#' @param error_family
#' A single character string (e.g. `"binomial"`). When
#' `"binomial"`, `compute_community_presence_absence()` is applied to
#' the wide community matrix before `filter_constant_taxa()`
#' during the viability check, mirroring the pipeline step.
#' @return
#' A single integer giving the optimal number of functional-type
#' groups (>= `functional_type_group_count_min` after clamping).
#' @details
#' For each candidate group count in
#' `functional_type_group_count_min`..
#' `functional_type_group_count_max` the function calls
#' `stats::cutree()` followed by `cluster::silhouette()` and
#' records the mean silhouette width.
#'
#' For each candidate `k` the community data are aggregated
#' to the FT level (summed `value` per
#' `(dataset_name, age, ft_group)`) and then passed through
#' the actual pipeline filter chain in sequence:
#' \enumerate{
#'   \item `filter_community_by_minimum_proportion()` at
#'     `minimum_proportion`.
#'   \item `filter_community_by_minimum_core_count()`.
#'   \item `filter_community_by_minimum_sample_count()`.
#'   \item `prepare_community_for_fit()` (wide matrix,
#'     using all surviving samples as their own IDs).
#'   \item `compute_community_presence_absence()` if
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
#'     `minimum_taxon_count`: return the highest-silhouette among
#'     those `k` values.
#'   \item If no `k` is viable: abort with `cli::cli_abort()`.
#' }
#'
#' Ties are broken by `base::which.max()` (first occurrence).
#' @seealso [compute_trait_dissimilarity()], [fit_hierarchical_clustering()],
#'   [assign_functional_type_clusters()]
#' @export
select_functional_type_group_count <- function(
    trait_dissimilarity,
    hierarchical_clustering,
    functional_type_group_count_min = 10L,
    functional_type_group_count_max = 25L,
    data_community,
    minimum_proportion,
    minimum_taxon_count,
    minimum_core_count,
    minimum_sample_count,
    error_family) {
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
      base::is.numeric(functional_type_group_count_max) ||
        base::is.integer(functional_type_group_count_max)
    ) &&
      base::length(functional_type_group_count_max) == 1L &&
      functional_type_group_count_max >= 2L,
    msg = base::paste0(
      "'functional_type_group_count_max' must be a single integer >= 2."
    )
  )

  assertthat::assert_that(
    (
      base::is.numeric(functional_type_group_count_min) ||
        base::is.integer(functional_type_group_count_min)
    ) &&
      base::length(functional_type_group_count_min) == 1L &&
      functional_type_group_count_min >= 2L,
    msg = base::paste0(
      "'functional_type_group_count_min' must be a single integer >= 2."
    )
  )

  assertthat::assert_that(
    functional_type_group_count_min <= functional_type_group_count_max,
    msg = stringr::str_glue(
      "'functional_type_group_count_min' ",
      "({functional_type_group_count_min}) must not exceed ",
      "'functional_type_group_count_max' ",
      "({functional_type_group_count_max})."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "'data_community' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c(
        "taxon", "dataset_name", "age", "value"
      ) %in%
        base::colnames(data_community)
    ),
    msg = stringr::str_c(
      "'data_community' must contain columns: ",
      "taxon, dataset_name, age, value."
    )
  )

  assertthat::assert_that(
    base::is.numeric(minimum_proportion) &&
      base::length(minimum_proportion) == 1L &&
      minimum_proportion > 0 &&
      minimum_proportion < 1,
    msg = "'minimum_proportion' must be a single numeric in (0, 1)."
  )

  assertthat::assert_that(
    (
      base::is.numeric(minimum_taxon_count) ||
        base::is.integer(minimum_taxon_count)
    ) &&
      base::length(minimum_taxon_count) == 1L &&
      minimum_taxon_count >= 1L,
    msg = "'minimum_taxon_count' must be a single positive integer."
  )

  assertthat::assert_that(
    (
      base::is.numeric(minimum_core_count) ||
        base::is.integer(minimum_core_count)
    ) &&
      base::length(minimum_core_count) == 1L &&
      minimum_core_count >= 1L,
    msg = "'minimum_core_count' must be a single positive integer."
  )

  assertthat::assert_that(
    (
      base::is.numeric(minimum_sample_count) ||
        base::is.integer(minimum_sample_count)
    ) &&
      base::length(minimum_sample_count) == 1L &&
      minimum_sample_count >= 1L,
    msg = "'minimum_sample_count' must be a single positive integer."
  )

  assertthat::assert_that(
    base::is.character(error_family) &&
      base::length(error_family) == 1L,
    msg = "'error_family' must be a single character string."
  )

  n_observations <-
    purrr::chuck(hierarchical_clustering, "order") |>
    base::length()

  functional_type_group_count_max <-
    base::min(
      base::as.integer(functional_type_group_count_max),
      n_observations - 1L
    )

  functional_type_group_count_min <-
    base::min(
      base::as.integer(functional_type_group_count_min),
      functional_type_group_count_max
    )

  candidate_group_counts <-
    base::seq(
      functional_type_group_count_min,
      functional_type_group_count_max
    )

  return_zero_on_filter_error <- function(condition) {
    return(0L)
  }

  mean_silhouette_widths <-
    candidate_group_counts |>
    purrr::map_dbl(
      .f = ~ {
        cluster_assignments <-
          stats::cutree(
            hierarchical_clustering,
            k = .x
          )

        silhouette_statistics <-
          cluster::silhouette(
            cluster_assignments,
            trait_dissimilarity
          )

        base::mean(silhouette_statistics[, "sil_width"])
      }
    )

  # Run the downstream filter chain for each candidate k to check viability.
  # Count the surviving non-constant FT group columns.
  surviving_group_counts <-
    candidate_group_counts |>
    purrr::map_int(
      .f = ~ {
        cluster_assignments <-
          stats::cutree(
            hierarchical_clustering,
            k = .x
          )

        data_taxon_clusters <-
          tibble::tibble(
            taxon = base::names(cluster_assignments),
            functional_type = base::as.character(
              base::unname(cluster_assignments)
            )
          )

        data_functional_type_community <-
          data_community |>
          dplyr::inner_join(
            data_taxon_clusters,
            by = dplyr::join_by(taxon)
          ) |>
          dplyr::group_by(
            .data[["dataset_name"]],
            .data[["age"]],
            .data[["functional_type"]]
          ) |>
          dplyr::summarise(
            value = base::sum(
              .data[["value"]],
              na.rm = TRUE
            ),
            .groups = "drop"
          ) |>
          dplyr::rename(taxon = "functional_type")

        base::tryCatch(
          {
            data_functional_type_community <-
              filter_community_by_minimum_proportion(
                data_community = data_functional_type_community,
                minimum_proportion = minimum_proportion
              )

            data_functional_type_community <-
              filter_community_by_minimum_core_count(
                data_community = data_functional_type_community,
                minimum_core_count = minimum_core_count
              )

            data_functional_type_community <-
              filter_community_by_minimum_sample_count(
                data_community = data_functional_type_community,
                minimum_sample_count = minimum_sample_count
              )

            data_sample_ids <-
              data_functional_type_community |>
              dplyr::distinct(
                .data[["dataset_name"]],
                .data[["age"]]
              )

            matrix_functional_type_community <-
              prepare_community_for_fit(
                data_community_long = data_functional_type_community,
                data_sample_ids = data_sample_ids
              )

            if (
              error_family == "binomial"
            ) {
              matrix_functional_type_community <-
                compute_community_presence_absence(
                  mat_community = matrix_functional_type_community
                )
            }

            matrix_functional_type_community <-
              filter_constant_taxa(
                data_community_matrix = matrix_functional_type_community
              )

            base::ncol(matrix_functional_type_community) |>
              base::as.integer()
          },
          error = return_zero_on_filter_error
        )
      }
    )

  viable_candidates <-
    surviving_group_counts >= minimum_taxon_count

  if (
    !base::any(viable_candidates)
  ) {
    cli::cli_abort(
      base::c(
        "x" = stringr::str_glue(
          "No viable k in {functional_type_group_count_min}..",
          "{functional_type_group_count_max} produces >=",
          " {minimum_taxon_count} non-constant FT groups after",
          " the pipeline filter chain."
        )
      )
    )
  }

  # Happy path: return the highest-silhouette k among viable candidates
  selected_group_count <-
    candidate_group_counts[viable_candidates][
      base::which.max(
        mean_silhouette_widths[viable_candidates]
      )
    ]

  return(selected_group_count)
}

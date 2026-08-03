#' @title Filter Community by Minimum Sample Count
#' @description
#' Filters out taxa that are not present in a sufficient number of
#' spatio-temporal samples (distinct dataset-age combinations). Only
#' taxa occurring in at least `minimum_sample_count` distinct
#' `(dataset_name, age)` combinations are retained. This removes
#' taxa that are present in too few interpolated time steps to
#' provide reliable co-occurrence signal.
#' @param data_community
#' A data frame containing community data in long format. Must include
#' columns `taxon`, `dataset_name`, and `age`.
#' @param minimum_sample_count
#' A single positive integer specifying the minimum number of distinct
#' spatio-temporal samples (dataset-age combinations) a taxon must
#' appear in to be retained. Default is 1 (no filtering).
#' @return
#' A filtered data frame containing only taxa that appear in at least
#' `minimum_sample_count` distinct spatio-temporal samples. All original
#' columns are preserved.
#' @details
#' The function counts distinct `(dataset_name, age)` combinations per
#' `taxon`. Taxa with fewer combinations than `minimum_sample_count` are
#' removed. An error is raised if no taxa remain after filtering, which
#' may indicate that `minimum_sample_count` is set too high.
#' @seealso [filter_community_by_minimum_core_count()],
#' [filter_community_by_minimum_proportion()],
#' [select_top_taxa_by_group_occurrence()]
#' @export
filter_community_by_minimum_sample_count <- function(
    data_community = NULL,
    minimum_sample_count = 1) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("taxon", "dataset_name", "age") %in%
        base::names(data_community)
    ),
    msg = stringr::str_c(
      "data_community must contain columns: ",
      stringr::str_c(
        base::c("taxon", "dataset_name", "age"),
        collapse = ", "
      )
    )
  )

  assertthat::assert_that(
    base::is.numeric(minimum_sample_count) &&
      base::length(minimum_sample_count) == 1L,
    msg = "minimum_sample_count must be a numeric scalar"
  )

  assertthat::assert_that(
    minimum_sample_count >= 1,
    msg = "minimum_sample_count must be greater than or equal to 1"
  )

  vec_retained_taxa <-
    data_community |>
    dplyr::distinct(taxon, dataset_name, age) |>
    dplyr::group_by(taxon) |>
    dplyr::summarise(
      .groups = "drop",
      n_samples = dplyr::n()
    ) |>
    dplyr::filter(n_samples >= minimum_sample_count) |>
    dplyr::pull(taxon)

  res_community_filtered <-
    data_community |>
    dplyr::filter(taxon %in% vec_retained_taxa)

  assertthat::assert_that(
    base::nrow(res_community_filtered) > 0L,
    msg = stringr::str_c(
      "No taxa remain after filtering. ",
      "The minimum_sample_count is too high."
    )
  )

  return(res_community_filtered)
}

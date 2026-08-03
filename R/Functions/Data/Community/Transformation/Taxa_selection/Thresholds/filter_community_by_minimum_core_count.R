#' @title Filter Community by Minimum Core Count
#' @description
#' Filters out taxa that are not present in a sufficient number of
#' cores (distinct datasets). Only taxa occurring in at least
#' `minimum_core_count` distinct `dataset_name` values are retained. This
#' removes taxa that appear in only a single core, which can
#' disproportionately influence the species-species co-occurrence matrix.
#' @param data_community
#' A data frame containing community data in long format. Must include
#' columns `taxon` and `dataset_name`.
#' @param minimum_core_count
#' A single positive integer specifying the minimum number of distinct
#' cores (datasets) a taxon must appear in to be retained. Default is 2.
#' @return
#' A filtered data frame containing only taxa that appear in at least
#' `minimum_core_count` distinct datasets. All original columns are preserved.
#' @details
#' The function counts distinct `dataset_name` values per `taxon` across
#' the entire dataset. Taxa with fewer cores than `minimum_core_count`
#' are removed. An error is raised if no taxa remain after filtering,
#' which may indicate that `minimum_core_count` is set too high.
#' @seealso [filter_community_by_minimum_sample_count()],
#' [filter_community_by_minimum_proportion()],
#' [select_top_taxa_by_group_occurrence()]
#' @export
filter_community_by_minimum_core_count <- function(
    data_community = NULL,
    minimum_core_count = 2) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("taxon", "dataset_name") %in%
        base::names(data_community)
    ),
    msg = stringr::str_c(
      "data_community must contain columns: ",
      stringr::str_c(
        base::c("taxon", "dataset_name"),
        collapse = ", "
      )
    )
  )

  assertthat::assert_that(
    base::is.numeric(minimum_core_count) &&
      base::length(minimum_core_count) == 1L,
    msg = "minimum_core_count must be a numeric scalar"
  )

  assertthat::assert_that(
    minimum_core_count >= 1,
    msg = "minimum_core_count must be greater than or equal to 1"
  )

  vec_retained_taxa <-
    data_community |>
    dplyr::distinct(taxon, dataset_name) |>
    dplyr::group_by(taxon) |>
    dplyr::summarise(
      .groups = "drop",
      n_cores = dplyr::n()
    ) |>
    dplyr::filter(n_cores >= minimum_core_count) |>
    dplyr::pull(taxon)

  res_community_filtered <-
    data_community |>
    dplyr::filter(taxon %in% vec_retained_taxa)

  assertthat::assert_that(
    base::nrow(res_community_filtered) > 0L,
    msg = stringr::str_c(
      "No taxa remain after filtering. ",
      "The minimum_core_count is too high."
    )
  )

  return(res_community_filtered)
}

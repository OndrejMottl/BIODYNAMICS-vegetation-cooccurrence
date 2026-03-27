#' @title Filter Taxa by Minimum Number of Cores
#' @description
#' Filters out taxa that are not present in a sufficient number of
#' cores (distinct datasets). Only taxa occurring in at least
#' `min_n_cores` distinct `dataset_name` values are retained. This
#' removes taxa that appear in only a single core, which can
#' disproportionately influence the species-species co-occurrence matrix.
#' @param data
#' A data frame containing community data in long format. Must include
#' columns `taxon` and `dataset_name`.
#' @param min_n_cores
#' A single positive integer specifying the minimum number of distinct
#' cores (datasets) a taxon must appear in to be retained. Default is 2.
#' @return
#' A filtered data frame containing only taxa that appear in at least
#' `min_n_cores` distinct datasets. All original columns are preserved.
#' @details
#' The function counts distinct `dataset_name` values per `taxon` across
#' the entire dataset. Taxa with fewer distinct cores than `min_n_cores`
#' are removed. An error is raised if no taxa remain after filtering,
#' which may indicate that `min_n_cores` is set too high.
#' @seealso [filter_community_by_n_samples()], [filter_rare_taxa()],
#' [select_n_taxa()]
#' @export
filter_community_by_n_cores <- function(
    data = NULL,
    min_n_cores = 2) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("taxon", "dataset_name") %in% names(data)),
    msg = paste(
      "data must contain columns:",
      paste(c("taxon", "dataset_name"), collapse = ", ")
    )
  )

  assertthat::assert_that(
    is.numeric(min_n_cores) && length(min_n_cores) == 1,
    msg = "min_n_cores must be a single numeric value"
  )

  assertthat::assert_that(
    min_n_cores >= 1,
    msg = "min_n_cores must be greater than or equal to 1"
  )

  vec_taxa_to_keep <-
    data |>
    dplyr::distinct(taxon, dataset_name) |>
    dplyr::group_by(taxon) |>
    dplyr::summarise(
      .groups = "drop",
      n_cores = dplyr::n()
    ) |>
    dplyr::filter(n_cores >= min_n_cores) |>
    dplyr::pull(taxon)

  res <-
    data |>
    dplyr::filter(taxon %in% vec_taxa_to_keep)

  assertthat::assert_that(
    nrow(res) > 0,
    msg = paste(
      "No taxa remain after filtering.",
      "The min_n_cores is too high."
    )
  )

  return(res)
}

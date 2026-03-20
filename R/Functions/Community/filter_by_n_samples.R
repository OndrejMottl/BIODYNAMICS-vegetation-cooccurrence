#' @title Filter Taxa by Minimum Number of Spatio-Temporal Samples
#' @description
#' Filters out taxa that are not present in a sufficient number of
#' spatio-temporal samples (distinct dataset-age combinations). Only
#' taxa occurring in at least `min_n_samples` distinct
#' `(dataset_name, age)` combinations are retained. This removes
#' taxa that are present in too few interpolated time steps to
#' provide reliable co-occurrence signal.
#' @param data
#' A data frame containing community data in long format. Must include
#' columns `taxon`, `dataset_name`, and `age`.
#' @param min_n_samples
#' A single positive integer specifying the minimum number of distinct
#' spatio-temporal samples (dataset-age combinations) a taxon must
#' appear in to be retained. Default is 1 (no filtering).
#' @return
#' A filtered data frame containing only taxa that appear in at least
#' `min_n_samples` distinct spatio-temporal samples. All original
#' columns are preserved.
#' @details
#' The function counts distinct `(dataset_name, age)` combinations per
#' `taxon`. Taxa with fewer combinations than `min_n_samples` are
#' removed. An error is raised if no taxa remain after filtering, which
#' may indicate that `min_n_samples` is set too high.
#' @seealso [filter_community_by_n_cores()], [filter_rare_taxa()],
#' [select_n_taxa()]
#' @export
filter_by_n_samples <- function(
    data = NULL,
    min_n_samples = 1) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("taxon", "dataset_name", "age") %in% names(data)),
    msg = paste(
      "data must contain columns:",
      paste(c("taxon", "dataset_name", "age"), collapse = ", ")
    )
  )

  assertthat::assert_that(
    is.numeric(min_n_samples) && length(min_n_samples) == 1,
    msg = "min_n_samples must be a single numeric value"
  )

  assertthat::assert_that(
    min_n_samples >= 1,
    msg = "min_n_samples must be greater than or equal to 1"
  )

  vec_taxa_to_keep <-
    data |>
    dplyr::distinct(taxon, dataset_name, age) |>
    dplyr::group_by(taxon) |>
    dplyr::summarise(
      .groups = "drop",
      n_samples = dplyr::n()
    ) |>
    dplyr::filter(n_samples >= min_n_samples) |>
    dplyr::pull(taxon)

  res <-
    data |>
    dplyr::filter(taxon %in% vec_taxa_to_keep)

  assertthat::assert_that(
    nrow(res) > 0,
    msg = paste(
      "No taxa remain after filtering.",
      "The min_n_samples is too high."
    )
  )

  return(res)
}

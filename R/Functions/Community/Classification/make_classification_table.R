#' @title Make Classification Table
#' @description
#' Creates a wide-format taxonomic classification table from a list of taxon
#' classification outputs.
#' @param data_source A list of data frames. Each data frame is expected to
#'   contain `sel_name` and a nested `classification` column. The nested
#'   `classification` table should contain `rank` and `name` columns.
#' @return A data frame in wide format with up to eight columns (`sel_name`
#'   plus one column per taxonomic rank) and one row per `sel_name`. Ranks
#'   not available for a given taxon are `NA`.
#' @details
#' The function removes `NULL` list elements, binds rows across all entries,
#' unnests `classification`, filters to standard taxonomic ranks (`kingdom`,
#' `phylum`, `class`, `order`, `family`, `genus`, `species`), removes
#' duplicate `sel_name`-`rank`-`name` combinations, and pivots to wide format.
#' `values_fn = dplyr::first` is used as a defensive guard if multiple names
#' are present for the same taxon and rank.
#' @export
make_classification_table <- function(data_source) {
  assertthat::assert_that(
    is.list(data_source),
    msg = "`data_source` must be a list of data frames."
  )

  res <-
    data_source |>
    dplyr::bind_rows() |>
    dplyr::filter(
      rank %in% c(
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    ) |>
    dplyr::distinct(
      sel_name, rank, name
    ) |>
    tidyr::pivot_wider(
      names_from = rank,
      values_from = name,
      values_fn = dplyr::first
    )

  return(res)
}

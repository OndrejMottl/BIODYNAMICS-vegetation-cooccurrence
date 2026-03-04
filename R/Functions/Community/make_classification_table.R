#' @title Make Classification Table
#' @description
#' Creates a wide-format taxonomic classification table from a list of data
#' frames containing taxon names and ranks. All seven standard taxonomic ranks
#' are retained: `kingdom`, `phylum`, `class`, `order`, `family`, `genus`,
#' and `species`.
#' @param data A list of data frames, each containing columns `sel_name`,
#'   `rank`, and `name`.
#' @return A data frame in wide format with up to eight columns (`sel_name`
#'   plus one column per taxonomic rank) and one row per `sel_name`. Ranks
#'   not available for a given taxon are `NA`.
#' @details
#' Filters for all seven standard taxonomic ranks (`kingdom`, `phylum`,
#' `class`, `order`, `family`, `genus`, `species`), removes duplicate
#' rank–name pairs, and pivots to wide format. `values_fn = dplyr::first`
#' is used as a defensive guard to prevent list columns in the rare case
#' where a taxon has more than one name recorded for the same rank.
#' @export
make_classification_table <- function(data) {
  dplyr::bind_rows(data) %>%
    dplyr::filter(
      rank %in% c(
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    ) %>%
    dplyr::distinct(
      sel_name, rank, name
    ) %>%
    tidyr::pivot_wider(
      names_from = rank,
      values_from = name,
      values_fn = dplyr::first
    ) %>%
    return()
}

#' @title Make Classification Table
#' @description
#' Creates a wide-format taxonomic classification table from a list of data
#' frames containing taxon names and ranks (e.g., family, genus, species).
#' @param data A list of data frames, each containing columns 'sel_name',
#'   'rank', and 'name'.
#' @return A data frame in wide format with columns for each taxonomic rank
#'   and one row per 'sel_name'.
#' @details
#' Filters for relevant taxonomic ranks, removes duplicates, and pivots the
#' table to wide format with one column per rank.
#' @export
make_classification_table <- function(data) {
  dplyr::bind_rows(data) %>%
    dplyr::filter(
      rank %in% c(
        "family", "genus", "species"
      )
    ) %>%
    dplyr::distinct(
      sel_name, rank, name
    ) %>%
    tidyr::pivot_wider(
      names_from = rank,
      values_from = name
    ) %>%
    return()
}

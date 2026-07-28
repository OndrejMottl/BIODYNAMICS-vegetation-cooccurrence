#' @title Get taxa without classification
#' @description
#' Identifies taxa from a community vector that are absent from a
#' classification table. Returns the names of taxa that do not have
#' a matching entry in the `sel_name` column of the classification
#' table.
#' @param vec_community_taxa
#' A non-empty character vector of taxon names present in the
#' community data.
#' @param data_classification_table
#' A data frame containing a `sel_name` column with unique taxon
#' names used for classification lookup. Must not contain duplicate
#' values in `sel_name`.
#' @return
#' A character vector of taxon names from `vec_community_taxa` that
#' are not found in `data_classification_table$sel_name`. Returns an
#' empty character vector if all taxa are classified.
#' @details
#' Uses `dplyr::anti_join()` to find taxa present in
#' `vec_community_taxa` but absent from the `sel_name` column of
#' `data_classification_table`. Duplicate entries in
#' `vec_community_taxa` are collapsed before the comparison, so
#' each unclassified taxon appears only once in the output.
#' @seealso
#' [classify_taxonomic_resolution()]
#' @export
get_taxa_without_classification <- function(vec_community_taxa, data_classification_table) {
  assertthat::assert_that(
    is.character(vec_community_taxa),
    length(vec_community_taxa) > 0,
    msg = "vec_community_taxa should be a non-empty character vector"
  )

  assertthat::assert_that(
    is.data.frame(data_classification_table),
    msg = "data_classification_table should be a data frame"
  )

  assertthat::assert_that(
    "sel_name" %in% names(data_classification_table),
    msg = "data_classification_table should contain a 'sel_name' column"
  )

  assertthat::assert_that(
    !any(duplicated(data_classification_table$sel_name)),
    msg = "data_classification_table should not contain duplicate 'sel_name' values"
  )

  missing_taxa <-
    dplyr::anti_join(
      data.frame(taxon = vec_community_taxa) |>
        dplyr::distinct(taxon),
      data_classification_table,
      by = dplyr::join_by("taxon" == "sel_name")
    ) |>
    dplyr::pull(taxon)


  return(missing_taxa)
}

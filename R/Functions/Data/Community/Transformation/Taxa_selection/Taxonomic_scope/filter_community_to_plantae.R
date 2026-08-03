#' @title Filter Community to Plantae
#' @description
#' Removes taxa that do not belong to the kingdom Plantae from a
#' community data frame, using a classification table to determine
#' the kingdom assignment for each taxon.
#' @param data_community
#' A data frame containing community data with at minimum a column
#' named 'taxon'.
#' @param data_classification_table
#' A data frame with columns 'sel_name' and 'kingdom', mapping
#' taxon names to their kingdom classification.
#' @return
#' A data frame identical in structure to `data_community` but with all rows
#' belonging to non-Plantae taxa removed. Taxa with 'kingdom = NA'
#' (unclassifiable) are also removed.
#' @details
#' Performs a left join between `data_community` and
#' `data_classification_table`
#' on 'taxon == sel_name' to retrieve the kingdom for each taxon.
#' Any taxon where 'kingdom' is not exactly '"Plantae"', including
#' taxa with 'kingdom = NA', is treated as non-plant and removed.
#' When any taxa are dropped, 'cli::cli_warn()' is issued reporting
#' the count and the full vector of removed taxon names.
#' Note: the upstream 'load_taxa_classification()' already filters
#' to Plantae during the taxospace lookup, so in practice this
#' function mainly catches taxa that are genuinely unclassifiable
#' (i.e. not found in any classification source).
#' @seealso [classify_taxonomic_resolution()],
#' [filter_community_by_minimum_proportion()]
#' @export
filter_community_to_plantae <- function(
    data_community,
    data_classification_table) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    "taxon" %in% base::colnames(data_community),
    msg = "data_community must contain a 'taxon' column"
  )

  assertthat::assert_that(
    base::is.data.frame(data_classification_table),
    msg = "data_classification_table must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("sel_name", "kingdom") %in%
        base::colnames(data_classification_table)
    ),
    msg = stringr::str_c(
      "data_classification_table must contain ",
      "columns: 'sel_name' and 'kingdom'"
    )
  )

  data_community_with_kingdom <-
    data_community |>
    dplyr::left_join(
      data_classification_table |>
        dplyr::select(sel_name, kingdom),
      by = dplyr::join_by("taxon" == "sel_name")
    )

  vec_removed_taxa <-
    data_community_with_kingdom |>
    dplyr::filter(
      base::is.na(kingdom) | kingdom != "Plantae"
    ) |>
    dplyr::distinct(taxon) |>
    dplyr::pull(taxon)

  if (
    base::length(vec_removed_taxa) > 0L
  ) {
    cli::cli_warn(
      base::c(
        "!" = stringr::str_c(
          "{base::length(vec_removed_taxa)} taxon/taxa ",
          "{?was/were} removed as non-Plantae or unclassified."
        ),
        "i" = "Removed: {.val {vec_removed_taxa}}"
      )
    )
  }

  res_community_plantae <-
    data_community_with_kingdom |>
    dplyr::filter(
      !base::is.na(kingdom) & kingdom == "Plantae"
    ) |>
    dplyr::select(-kingdom)

  return(res_community_plantae)
}

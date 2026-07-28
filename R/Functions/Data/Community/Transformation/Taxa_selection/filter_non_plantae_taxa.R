#' @title Filter Non-Plantae Taxa
#' @description
#' Removes taxa that do not belong to the kingdom Plantae from a
#' community data frame, using a classification table to determine
#' the kingdom assignment for each taxon.
#' @param data
#' A data frame containing community data with at minimum a column
#' named 'taxon'.
#' @param data_classification_table
#' A data frame with columns 'sel_name' and 'kingdom', mapping
#' taxon names to their kingdom classification.
#' @return
#' A data frame identical in structure to 'data' but with all rows
#' belonging to non-Plantae taxa removed. Taxa with 'kingdom = NA'
#' (unclassifiable) are also removed.
#' @details
#' Performs a left join between 'data' and 'data_classification_table'
#' on 'taxon == sel_name' to retrieve the kingdom for each taxon.
#' Any taxon where 'kingdom' is not exactly '"Plantae"', including
#' taxa with 'kingdom = NA', is treated as non-plant and removed.
#' When any taxa are dropped, 'cli::cli_warn()' is issued reporting
#' the count and the full vector of removed taxon names.
#' Note: the upstream 'get_taxa_classification()' already filters
#' to Plantae during the taxospace lookup, so in practice this
#' function mainly catches taxa that are genuinely unclassifiable
#' (i.e. not found in any classification source).
#' @seealso [classify_taxonomic_resolution()], [filter_rare_taxa()]
#' @export
filter_non_plantae_taxa <- function(data, data_classification_table) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    "taxon" %in% colnames(data),
    msg = "data must contain a 'taxon' column"
  )

  assertthat::assert_that(
    is.data.frame(data_classification_table),
    msg = "data_classification_table must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("sel_name", "kingdom") %in%
        colnames(data_classification_table)
    ),
    msg = paste(
      "data_classification_table must contain",
      "columns: 'sel_name' and 'kingdom'"
    )
  )

  data_with_kingdom <-
    data |>
    dplyr::left_join(
      data_classification_table |>
        dplyr::select(sel_name, kingdom),
      by = dplyr::join_by("taxon" == "sel_name")
    )

  vec_dropped_taxa <-
    data_with_kingdom |>
    dplyr::filter(
      base::is.na(kingdom) | kingdom != "Plantae"
    ) |>
    dplyr::distinct(taxon) |>
    dplyr::pull(taxon)

  if (base::length(vec_dropped_taxa) > 0) {
    cli::cli_warn(
      c(
        "!" = paste0(
          "{base::length(vec_dropped_taxa)} taxon/taxa ",
          "{?was/were} removed as non-Plantae or unclassified."
        ),
        "i" = "Removed: {.val {vec_dropped_taxa}}"
      )
    )
  }

  res <-
    data_with_kingdom |>
    dplyr::filter(
      !base::is.na(kingdom) & kingdom == "Plantae"
    ) |>
    dplyr::select(-kingdom)

  return(res)
}

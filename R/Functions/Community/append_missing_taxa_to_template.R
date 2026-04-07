#' @title Append missing taxa to the shared template CSV
#' @description
#' Reads the existing missing-taxa template CSV (if present),
#' removes any entries that are now present in
#' `data_classification_table` (i.e. have since been classified),
#' appends any new unclassified taxa, deduplicates by `sel_name`,
#' and writes the result back to disk. If the file does not yet
#' exist it is created. Nothing is written when `data_missing_taxa`
#' is empty, the file already exists, and no stale entries need to
#' be removed.
#' @param data_missing_taxa
#' A tibble with columns `sel_name`, `kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, and `species` (all character).
#' Rows represent taxa that could not be classified. Pass an empty
#' tibble (zero rows) when there are no new missing taxa.
#' @param file_path
#' A length-1 character string giving the path to the CSV file.
#' Defaults to
#' `here::here("Data/Input/missing_taxa_template.csv")`.
#' @param data_classification_table
#' `NULL` (default) or a data frame with at least a `sel_name`
#' column. When provided, any entry already present in the
#' existing template whose `sel_name` also appears in this table
#' is removed from the template before merging. This prevents
#' stale entries from re-appearing after a taxon has been manually
#' added to the auxiliary classification table.
#' @return
#' The `file_path` string (invisibly), so it can be used as a
#' `format = "file"` target return value in a {targets} pipeline.
#' @details
#' The file is only written when at least one of the following is
#' true:
#' \itemize{
#'   \item `data_missing_taxa` contains one or more rows.
#'   \item The file at `file_path` does not yet exist.
#'   \item `data_classification_table` is not `NULL` and at least
#'     one existing template entry is now classified.
#' }
#' Deduplication keeps the first occurrence of each `sel_name`.
#' @seealso
#' [get_aux_classification_table()],
#' [get_taxa_without_classification()],
#' [check_and_report_missing_taxa()]
#' @export
append_missing_taxa_to_template <- function(
    data_missing_taxa,
    file_path = here::here(
      "Data/Input/missing_taxa_template.csv"
    ),
    data_classification_table = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_missing_taxa),
    msg = "'data_missing_taxa' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(file_path) &&
      base::length(file_path) == 1L,
    msg = "'file_path' must be a single character string."
  )

  assertthat::assert_that(
    base::is.null(data_classification_table) ||
      base::is.data.frame(data_classification_table),
    msg = "'data_classification_table' must be NULL or a data frame."
  )

  assertthat::assert_that(
    base::is.null(data_classification_table) ||
      "sel_name" %in% base::colnames(data_classification_table),
    msg = "'data_classification_table' must contain a 'sel_name' column."
  )

  needs_write <-
    base::nrow(data_missing_taxa) > 0L ||
      !base::file.exists(file_path)

  data_existing <-
    get_aux_classification_table(file_path = file_path)

  # Remove entries that are now present in the classification table
  if (
    !base::is.null(data_classification_table) &&
      base::nrow(data_existing) > 0L
  ) {
    data_existing_filtered <-
      dplyr::anti_join(
        data_existing,
        data_classification_table,
        by = dplyr::join_by(sel_name)
      )

    # If stale entries were removed, we also need to rewrite the file
    if (
      base::nrow(data_existing_filtered) < base::nrow(data_existing)
    ) {
      needs_write <- TRUE
    }

    data_existing <-
      data_existing_filtered
  }

  if (
    base::isFALSE(needs_write)
  ) {
    return(invisible(file_path))
  }

  data_updated <-
    dplyr::bind_rows(
      data_existing,
      data_missing_taxa
    ) |>
    dplyr::distinct(
      .data[["sel_name"]],
      .keep_all = TRUE
    )

  readr::write_csv(
    x = data_updated,
    file = file_path,
    na = "NA"
  )

  return(invisible(file_path))
}

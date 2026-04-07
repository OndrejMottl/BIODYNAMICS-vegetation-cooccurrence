#' @title Append missing taxa to the shared template CSV
#' @description
#' Reads the existing missing-taxa template CSV (if present),
#' appends any new unclassified taxa, deduplicates by `sel_name`,
#' and writes the result back to disk. If the file does not yet
#' exist it is created. Nothing is written when `data_missing_taxa`
#' is empty and the file already exists.
#' @param data_missing_taxa
#' A tibble with columns `sel_name`, `kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, and `species` (all character).
#' Rows represent taxa that could not be classified. Pass an empty
#' tibble (zero rows) when there are no new missing taxa.
#' @param file_path
#' A length-1 character string giving the path to the CSV file.
#' Defaults to
#' `here::here("Data/Input/missing_taxa_template.csv")`.
#' @return
#' The `file_path` string (invisibly), so it can be used as a
#' `format = "file"` target return value in a {targets} pipeline.
#' @details
#' The file is only written when at least one of the following is
#' true:
#' \itemize{
#'   \item `data_missing_taxa` contains one or more rows.
#'   \item The file at `file_path` does not yet exist.
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
    )) {
  assertthat::assert_that(
    base::is.data.frame(data_missing_taxa),
    msg = "'data_missing_taxa' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(file_path) &&
      base::length(file_path) == 1L,
    msg = "'file_path' must be a single character string."
  )

  needs_write <-
    base::nrow(data_missing_taxa) > 0L ||
      !base::file.exists(file_path)

  if (
    base::isFALSE(needs_write)
  ) {
    return(invisible(file_path))
  }

  data_existing <-
    get_aux_classification_table(file_path = file_path)

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

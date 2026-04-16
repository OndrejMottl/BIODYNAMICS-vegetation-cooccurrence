#' @title Check for missing taxa and stop pipeline if any are found
#' @description
#' Validates that all community taxa have been classified. When
#' missing taxa are found, stops with an informative error message
#' listing the count of unclassified taxa. Returns `TRUE` invisibly
#' when no taxa are missing.
#' @param vec_taxa_without_classification
#' A character vector of taxon names that could not be classified
#' automatically or via the auxiliary table. An empty vector
#' (`character(0)`) signals full coverage and causes the function
#' to return silently.
#' @param file_missing_taxa_template
#' `NULL` by default. Optional placeholder for a targets file
#' dependency. When supplied in a pipeline, it ensures the missing
#' taxa CSV is written before the error is raised.
#' @return
#' `TRUE` invisibly when every taxon is classified.
#' Stops with an error when any taxa are missing.
#' @details
#' The missing taxa are stored as a targets object
#' `data_missing_taxa_template` in the pipeline store. Inspect them
#' with `targets::tar_read("data_missing_taxa_template")`. During a
#' pipeline run the same rows are also appended to
#' `Data/Input/missing_taxa_template.csv` for manual review. The
#' object is a `tibble` with columns `sel_name`, `kingdom`,
#' `phylum`, `class`, `order`, `family`, `genus`, and `species`;
#' rank columns are left as `NA` for manual completion. Fill in the
#' missing classifications and copy or append rows to
#' `Data/Input/aux_classification_table.csv`, then re-run the
#' pipeline. Use the helper script in
#' `R/03_Supplementary_analyses/Classification/`
#' to coalesce templates across all pipeline stores into one CSV.
#' @seealso
#' [get_aux_classification_table()],
#' [combine_classification_tables()],
#' [get_taxa_without_classification()]
#' @examples
#' check_and_report_missing_taxa(
#'   vec_taxa_without_classification = base::character(0)
#' )
#'
#' base::try(
#'   check_and_report_missing_taxa(
#'     vec_taxa_without_classification = base::c("Taxon_a")
#'   )
#' )
#' @export
check_and_report_missing_taxa <- function(
    vec_taxa_without_classification,
    file_missing_taxa_template = NULL) {
  base::force(x = file_missing_taxa_template)

  assertthat::assert_that(
    base::is.character(vec_taxa_without_classification),
    msg = "vec_taxa_without_classification must be a character vector"
  )

  if (
    base::length(vec_taxa_without_classification) == 0
  ) {
    return(base::invisible(TRUE))
  }

  text_message <-
    stringr::str_c(
      base::length(vec_taxa_without_classification),
      " taxon/taxa could not be classified.\n",
      "Inspect missing taxa with:\n",
      "  targets::tar_read('data_missing_taxa_template')\n",
      "The pipeline also appends them to:\n",
      "  Data/Input/missing_taxa_template.csv\n",
      "Fill in the missing classifications and copy/append to\n",
      "  Data/Input/aux_classification_table.csv\n",
      "then re-run the pipeline."
    )

  cli::cli_abort(
    message = text_message,
    call = NULL
  )
}

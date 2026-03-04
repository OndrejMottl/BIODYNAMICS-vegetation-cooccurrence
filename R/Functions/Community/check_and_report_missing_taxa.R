#' @title Check for missing taxa and write template if needed
#' @description
#' Validates that all community taxa have been classified. When
#' missing taxa are found, writes a template CSV to
#' `template_file_path` so the user can fill in manual
#' classifications, then stops with an informative error message.
#' Returns `TRUE` invisibly when no taxa are missing.
#' @param vec_taxa_without_classification
#' A character vector of taxon names that could not be classified
#' automatically or via the auxiliary table. An empty vector
#' (`character(0)`) signals full coverage and causes the function
#' to return silently.
#' @param template_file_path
#' A length-1 character string giving the path where the template
#' CSV will be written when missing taxa are found. Defaults to
#' `here::here("Data/Input/missing_taxa_template.csv")`.
#' @return
#' `TRUE` invisibly when every taxon is classified.
#' Stops with an error (and writes a template CSV) when any taxa
#' are missing.
#' @details
#' The template CSV contains columns `sel_name`, `kingdom`,
#' `phylum`, `class`, `order`, `family`, `genus`, and `species`.
#' The `sel_name` column is pre-filled with the missing taxon
#' names; all rank columns are left as `NA` for the user to
#' complete. At minimum, `family`, `genus`, or `species` should be
#' filled in. After completing the template, copy or append rows
#' to `Data/Input/aux_classification_table.csv` and re-run the
#' pipeline.
#' @seealso
#' [get_aux_classification_table()],
#' [combine_classification_tables()],
#' [get_taxa_without_classification()]
#' @export
check_and_report_missing_taxa <- function(
    vec_taxa_without_classification,
    template_file_path = here::here(
      "Data/Input/missing_taxa_template.csv"
    )) {
  assertthat::assert_that(
    is.character(vec_taxa_without_classification),
    msg = paste(
      "vec_taxa_without_classification must be",
      "a character vector"
    )
  )

  assertthat::assert_that(
    is.character(template_file_path) &&
      length(template_file_path) == 1,
    msg = "template_file_path must be a single character string"
  )

  if (
    length(vec_taxa_without_classification) == 0
    ) {
    return(invisible(TRUE))
  }

  data_template <-
    tibble::tibble(
      sel_name = vec_taxa_without_classification,
      kingdom = NA_character_,
      phylum = NA_character_,
      class = NA_character_,
      order = NA_character_,
      family = NA_character_,
      genus = NA_character_,
      species = NA_character_
    )

  readr::write_csv(
    x = data_template,
    file = template_file_path
  )

  stop(
    length(vec_taxa_without_classification),
    " taxon/taxa could not be classified. A template CSV has been",
    " written to: ", template_file_path, "\n",
    "Fill in the missing classifications and copy/append to\n",
    "  Data/Input/aux_classification_table.csv\n",
    "then re-run the pipeline.",
    call. = FALSE
  )
}

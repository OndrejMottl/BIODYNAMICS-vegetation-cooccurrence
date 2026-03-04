#' @title Get auxiliary classification table
#' @description
#' Reads the manually curated auxiliary classification table from a
#' CSV file. If the file does not yet exist, returns an empty tibble
#' with the required columns so that the rest of the pipeline can
#' continue and detect any missing taxa.
#' @param file_path
#' A length-1 character string giving the path to the CSV file.
#' Defaults to
#' `here::here("Data/Input/aux_classification_table.csv")`.
#' The file, if present, must contain a `sel_name` column. All
#' seven taxonomic rank columns (`kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, `species`) are expected but
#' optional — any that are absent are filled with `NA_character_`.
#' @return
#' A tibble with columns `sel_name`, `kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, and `species` (all character).
#' Returns an empty tibble when the file does not exist.
#' @details
#' Manual classifications in this file override automatic
#' classifications produced by `get_taxa_classification()`. When
#' the file exists it is validated to confirm `sel_name` is
#' present. Any of the seven rank columns that are absent are
#' filled with `NA_character_` rather than raising an error, so
#' that partial tables (e.g., those that only specify `family`,
#' `genus`, and `species`) continue to be accepted.
#' @seealso
#' [combine_classification_tables()],
#' [check_and_report_missing_taxa()]
#' @export
get_aux_classification_table <- function(
    file_path = here::here("Data/Input/aux_classification_table.csv")) {
  assertthat::assert_that(
    is.character(file_path) && length(file_path) == 1,
    msg = "file_path must be a single character string"
  )

  res_empty <-
    tibble::tibble(
      sel_name = character(0),
      kingdom = character(0),
      phylum = character(0),
      class = character(0),
      order = character(0),
      family = character(0),
      genus = character(0),
      species = character(0)
    )

  if (!file.exists(file_path)) {
    return(res_empty)
  }

  res_raw <-
    readr::read_csv(
      file_path,
      show_col_types = FALSE
    )

  assertthat::assert_that(
    "sel_name" %in% colnames(res_raw),
    msg = paste(
      "aux_classification_table.csv must contain",
      "a 'sel_name' column"
    )
  )

  # Fill any missing expected columns with NA so combining works
  vec_expected_cols <- c(
    "kingdom", "phylum", "class", "order",
    "family", "genus", "species"
  )

  for (
    col_name in vec_expected_cols
    ) {
    if (!col_name %in% colnames(res_raw)) {
      res_raw <-
        res_raw %>%
        dplyr::mutate(!!col_name := NA_character_)
    }
  }

  res <-
    res_raw %>%
    dplyr::select(
      dplyr::all_of(c("sel_name", vec_expected_cols))
    ) %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        as.character
      )
    )

  return(res)
}

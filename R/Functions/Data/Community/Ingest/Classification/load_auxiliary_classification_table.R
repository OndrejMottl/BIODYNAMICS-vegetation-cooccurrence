#' @title Load an auxiliary classification table
#' @description
#' Reads the manually curated auxiliary classification table from a
#' CSV file. If the file does not yet exist, returns an empty tibble
#' with the required columns so that the rest of the pipeline can
#' continue and detect any missing taxa.
#' @param file_auxiliary_classification_table
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
#' classifications produced by `load_taxa_classification()`. When
#' the file exists it is validated to confirm `sel_name` is
#' present. Any of the seven rank columns that are absent are
#' filled with `NA_character_` rather than raising an error, so
#' that partial tables (e.g., those that only specify `family`,
#' `genus`, and `species`) continue to be accepted.
#' @seealso
#' [build_combined_classification_table()],
#' [validate_taxa_classification_coverage()]
#' @export
load_auxiliary_classification_table <- function(
    file_auxiliary_classification_table = here::here(
      "Data/Input/aux_classification_table.csv"
    )) {
  assertthat::assert_that(
    base::is.character(file_auxiliary_classification_table) &&
      base::length(file_auxiliary_classification_table) == 1,
    msg = stringr::str_c(
      "file_auxiliary_classification_table must be a single ",
      "character string"
    )
  )

  res_auxiliary_classification_table_empty <-
    tibble::tibble(
      sel_name = base::character(0),
      kingdom = base::character(0),
      phylum = base::character(0),
      class = base::character(0),
      order = base::character(0),
      family = base::character(0),
      genus = base::character(0),
      species = base::character(0)
    )

  if (
    !base::file.exists(file_auxiliary_classification_table)
  ) {
    return(res_auxiliary_classification_table_empty)
  }

  data_auxiliary_classification_table_raw <-
    readr::read_csv(
      file_auxiliary_classification_table,
      show_col_types = FALSE
    )

  assertthat::assert_that(
    "sel_name" %in%
      base::colnames(data_auxiliary_classification_table_raw),
    msg = stringr::str_c(
      "aux_classification_table.csv must contain ",
      "a 'sel_name' column"
    )
  )

  # Fill any missing expected columns with NA so combining works
  vec_expected_columns <-
    base::c(
      "kingdom", "phylum", "class", "order",
      "family", "genus", "species"
    )

  vec_missing_columns <-
    base::setdiff(
      vec_expected_columns,
      base::colnames(data_auxiliary_classification_table_raw)
    )

  data_auxiliary_classification_table_prepared <-
    purrr::reduce(
      .x = vec_missing_columns,
      .init = data_auxiliary_classification_table_raw,
      .f = ~ .x |>
        dplyr::mutate(
          !!.y := NA_character_
        )
    )

  res_auxiliary_classification_table <-
    data_auxiliary_classification_table_prepared |>
    dplyr::select(
      dplyr::all_of(
        base::c("sel_name", vec_expected_columns)
      )
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        base::as.character
      )
    )

  return(res_auxiliary_classification_table)
}

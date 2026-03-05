#' @title Combine automatic and auxiliary classification tables
#' @description
#' Merges the automatically generated classification table with a
#' manually curated auxiliary table. When the same `sel_name` entry
#' exists in both tables the auxiliary (manual) row takes priority,
#' overriding the automatic classification entirely.
#' @param data_classification_table
#' A data frame produced by `make_classification_table()` with
#' columns `sel_name`, `kingdom`, `phylum`, `class`, `order`,
#' `family`, `genus`, and `species`.
#' @param data_aux_classification_table
#' A data frame produced by `get_aux_classification_table()` with
#' columns `sel_name`, `kingdom`, `phylum`, `class`, `order`,
#' `family`, `genus`, and `species`. May be an empty tibble
#' (zero rows) when no manual overrides exist.
#' @return
#' A tibble with columns `sel_name`, `kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, and `species` containing all unique
#' taxa from both inputs. Manual entries override automatic ones
#' on `sel_name` collision. Only columns present in both inputs
#' are retained (intersection).
#' @details
#' Binding is performed by placing auxiliary rows before automatic
#' rows and then retaining the first occurrence of each `sel_name`
#' via `dplyr::distinct()`. This guarantees that manual
#' classifications always win regardless of their relative
#' completeness.
#' @seealso
#' [get_aux_classification_table()],
#' [make_classification_table()],
#' [classify_taxonomic_resolution()]
#' @export
combine_classification_tables <- function(
    data_classification_table,
    data_aux_classification_table) {
  assertthat::assert_that(
    is.data.frame(data_classification_table),
    msg = "data_classification_table must be a data frame"
  )

  assertthat::assert_that(
    "sel_name" %in% colnames(data_classification_table),
    msg = paste(
      "data_classification_table must contain",
      "a 'sel_name' column"
    )
  )

  assertthat::assert_that(
    is.data.frame(data_aux_classification_table),
    msg = "data_aux_classification_table must be a data frame"
  )

  assertthat::assert_that(
    "sel_name" %in% colnames(data_aux_classification_table),
    msg = paste(
      "data_aux_classification_table must contain",
      "a 'sel_name' column"
    )
  )

  vec_shared_cols <-
    intersect(
      colnames(data_classification_table),
      colnames(data_aux_classification_table)
    )

  # Auxiliary rows first so dplyr::distinct keeps them on collision
  res <-
    dplyr::bind_rows(
      data_aux_classification_table %>%
        dplyr::select(dplyr::all_of(vec_shared_cols)),
      data_classification_table %>%
        dplyr::select(dplyr::all_of(vec_shared_cols))
    ) %>%
    dplyr::distinct(sel_name, .keep_all = TRUE)

  return(res)
}

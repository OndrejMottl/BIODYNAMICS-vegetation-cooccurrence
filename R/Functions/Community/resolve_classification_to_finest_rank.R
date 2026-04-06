#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Resolve classification to finest taxonomic rank
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
#' @title Resolve Classification to Finest Rank
#' @description
#' For each taxon in a wide-format taxonomic classification table,
#' selects the value from the finest available rank
#' (genus > family > order > class > phylum > kingdom). Species
#' rank is excluded by design so that taxa classified to species
#' level are resolved to genus. The result maps every `sel_name`
#' to a single `taxon_genus` value taken from whatever the finest
#' non-`NA` rank is.
#' @param data_classification_table
#' A wide-format data frame (e.g. output of
#' `make_classification_table()`) containing a `sel_name` column
#' plus taxonomic rank columns: `kingdom`, `phylum`, `class`,
#' `order`, `family`, and `genus`. All rank columns may contain
#' `NA` for unavailable ranks.
#' @param col_name_taxon
#' A single non-empty character string giving the name of the
#' output column that holds the resolved taxon name. Defaults to
#' `"taxon_genus"`.
#' @return
#' A tibble with two columns: `sel_name` (character) and the
#' column named by `col_name_taxon` (character, default
#' `"taxon_genus"`). One row is returned per unique `sel_name`.
#' The resolved column holds the taxon name at the finest
#' available rank, or `NA` if no rank column was non-`NA`.
#' @details
#' The function pivots the six rank columns to long format,
#' removes `NA` rank values, assigns a numeric rank order
#' (kingdom = 1, …, genus = 6), and for each `sel_name` retains
#' the row with the highest rank order via `dplyr::slice_max()`.
#' Ties are broken arbitrarily (`with_ties = FALSE`). The rank
#' order and the intermediate `rank` column are dropped before
#' returning, leaving only `sel_name` and the column named by
#' `col_name_taxon`.
#' @seealso [make_classification_table()]
#' @export
resolve_classification_to_finest_rank <- function(
    data_classification_table,
    col_name_taxon = "taxon_genus") {
  assertthat::assert_that(
    base::is.character(col_name_taxon),
    base::length(col_name_taxon) == 1L,
    base::nchar(col_name_taxon) > 0L,
    msg = base::paste0(
      "`col_name_taxon` must be a single non-empty character ",
      "string."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_classification_table),
    msg = base::paste0(
      "`data_classification_table` must be a data frame, ",
      "not ", base::class(data_classification_table)[1], "."
    )
  )

  vec_ranks <-
    base::c(
      "kingdom",
      "phylum",
      "class",
      "order",
      "family",
      "genus"
    )

  vec_required_columns <-
    base::c(
      "sel_name", vec_ranks
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_classification_table)
    ),
    msg = base::paste0(
      "`data_classification_table` must contain columns: ",
      base::paste(vec_required_columns, collapse = ", "), "."
    )
  )

  data_rank_order <-
    tibble::tibble(
      rank = vec_ranks,
      rank_order = base::seq_along(vec_ranks)
    )

  res <-
    data_classification_table |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(vec_ranks),
      names_to = "rank",
      values_to = col_name_taxon
    ) |>
    dplyr::filter(
      !base::is.na(.data[[col_name_taxon]])
    ) |>
    dplyr::left_join(
      data_rank_order,
      by = dplyr::join_by("rank"),
      relationship = "many-to-one"
    ) |>
    dplyr::group_by(.data[["sel_name"]]) |>
    dplyr::slice_max(
      order_by = .data[["rank_order"]],
      n = 1L,
      with_ties = FALSE
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      dplyr::all_of(base::c("sel_name", col_name_taxon))
    )

  return(res)
}

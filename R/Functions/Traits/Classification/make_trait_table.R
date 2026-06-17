#' @title Make Wide-Format Species x Traits Table
#' @description
#' Pivots a long-format aggregated trait data frame into a wide-format
#' table with one row per taxon and one column per trait domain. This
#' produces the genus x traits matrix used for functional type
#' assignment.
#' @param data
#' A data frame in long format with one row per taxon x trait
#' combination. Must contain at least the columns specified by
#' `taxon_col`, `trait_col`, and `value_col`.
#' @param taxon_col
#' A character string naming the column containing taxon (genus) names.
#' Default: `"taxon_name"`.
#' @param trait_col
#' A character string naming the column containing trait domain names.
#' Default: `"trait_domain_name"`.
#' @param value_col
#' A character string naming the column containing aggregated trait
#' values. Default: `"trait_value_aggregated"`.
#' @return
#' A tibble with one row per taxon and one column per trait domain,
#' plus the taxon name column. Column names for traits are taken
#' directly from the values in `trait_col`.
#' @details
#' Wraps `tidyr::pivot_wider()`. If a taxon x trait combination appears
#' more than once, only the first value is retained
#' (`values_fn = dplyr::first`).
#' @seealso [aggregate_trait_values()], [check_trait_coverage()]
#' @export
make_trait_table <- function(
    data,
    taxon_col = "taxon_name",
    trait_col = "trait_domain_name",
    value_col = "trait_value_aggregated") {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(taxon_col) &&
      base::length(taxon_col) == 1L,
    msg = "'taxon_col' must be a single character string."
  )

  assertthat::assert_that(
    taxon_col %in% base::colnames(data),
    msg = base::paste0(
      "'taxon_col' column '", taxon_col,
      "' not found in 'data'."
    )
  )

  assertthat::assert_that(
    base::is.character(trait_col) &&
      base::length(trait_col) == 1L,
    msg = "'trait_col' must be a single character string."
  )

  assertthat::assert_that(
    trait_col %in% base::colnames(data),
    msg = base::paste0(
      "'trait_col' column '", trait_col,
      "' not found in 'data'."
    )
  )

  assertthat::assert_that(
    base::is.character(value_col) &&
      base::length(value_col) == 1L,
    msg = "'value_col' must be a single character string."
  )

  assertthat::assert_that(
    value_col %in% base::colnames(data),
    msg = base::paste0(
      "'value_col' column '", value_col,
      "' not found in 'data'."
    )
  )

  res <-
    data |>
    tidyr::pivot_wider(
      id_cols = dplyr::all_of(taxon_col),
      names_from = dplyr::all_of(trait_col),
      values_from = dplyr::all_of(value_col),
      values_fn = dplyr::first
    )

  return(res)
}

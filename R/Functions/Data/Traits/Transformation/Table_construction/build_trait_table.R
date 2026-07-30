#' @title Build Wide-Format Species x Traits Table
#' @description
#' Pivots a long-format aggregated trait data frame into a wide-format
#' table with one row per taxon and one column per trait domain. This
#' produces the genus x traits matrix used for functional type
#' assignment.
#' @param data_aggregated_trait_values
#' A data frame in long format with one row per taxon x trait
#' combination. Must contain at least the columns specified by
#' `taxon_column`, `trait_domain_column`, and `trait_value_column`.
#' @param taxon_column
#' A character string naming the column containing taxon (genus) names.
#' Default: `"taxon_name"`.
#' @param trait_domain_column
#' A character string naming the column containing trait domain names.
#' Default: `"trait_domain_name"`.
#' @param trait_value_column
#' A character string naming the column containing aggregated trait
#' values. Default: `"trait_value_aggregated"`.
#' @return
#' A tibble with one row per taxon and one column per trait domain,
#' plus the taxon name column. Column names for traits are taken
#' directly from the values in `trait_domain_column`.
#' @details
#' Wraps `tidyr::pivot_wider()`. If a taxon x trait combination appears
#' more than once, only the first value is retained
#' (`values_fn = dplyr::first`).
#' @seealso [aggregate_trait_values()], [summarise_trait_coverage()]
#' @export
build_trait_table <- function(
    data_aggregated_trait_values,
    taxon_column = "taxon_name",
    trait_domain_column = "trait_domain_name",
    trait_value_column = "trait_value_aggregated") {
  assertthat::assert_that(
    base::is.data.frame(data_aggregated_trait_values),
    msg = "'data_aggregated_trait_values' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(taxon_column) &&
      base::length(taxon_column) == 1L,
    msg = "'taxon_column' must be a single character string."
  )

  assertthat::assert_that(
    taxon_column %in% base::colnames(data_aggregated_trait_values),
    msg = base::paste0(
      "'taxon_column' column '", taxon_column,
      "' not found in 'data_aggregated_trait_values'."
    )
  )

  assertthat::assert_that(
    base::is.character(trait_domain_column) &&
      base::length(trait_domain_column) == 1L,
    msg = "'trait_domain_column' must be a single character string."
  )

  assertthat::assert_that(
    trait_domain_column %in% base::colnames(data_aggregated_trait_values),
    msg = base::paste0(
      "'trait_domain_column' column '", trait_domain_column,
      "' not found in 'data_aggregated_trait_values'."
    )
  )

  assertthat::assert_that(
    base::is.character(trait_value_column) &&
      base::length(trait_value_column) == 1L,
    msg = "'trait_value_column' must be a single character string."
  )

  assertthat::assert_that(
    trait_value_column %in% base::colnames(data_aggregated_trait_values),
    msg = base::paste0(
      "'trait_value_column' column '", trait_value_column,
      "' not found in 'data_aggregated_trait_values'."
    )
  )

  data_trait_table <-
    data_aggregated_trait_values |>
    tidyr::pivot_wider(
      id_cols = dplyr::all_of(taxon_column),
      names_from = dplyr::all_of(trait_domain_column),
      values_from = dplyr::all_of(trait_value_column),
      values_fn = dplyr::first
    )

  return(data_trait_table)
}

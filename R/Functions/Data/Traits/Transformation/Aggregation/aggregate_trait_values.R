#' @title Aggregate Trait Values to Single Value per Group
#' @description
#' Aggregates a long-format trait data frame to one row per group (by
#' default per taxon x trait combination) using a specified summary
#' function. Intended to be applied after outlier removal.
#' @param data_trait_values
#' A data frame in long format with at least the columns specified by
#' `trait_value_column` and `group_columns`.
#' @param trait_value_column
#' A character string naming the numeric column containing trait values.
#' Default: `"trait_value"`.
#' @param group_columns
#' A character vector of column names used to define groups for
#' aggregation. Default: `c("taxon_name", "trait_domain_name")`.
#' @param aggregation_method
#' A character string specifying the aggregation function. One of
#' `"median"` (default) or `"mean"`. Matched with `match.arg()`.
#' @return
#' A data frame with one row per unique combination of `group_columns` and
#' a new column `trait_value_aggregated` containing the aggregated value.
#' @details
#' The `aggregation_method` argument is processed via `match.arg()`, so
#' partial matching is supported (e.g. `"med"` resolves to `"median"`).
#' @seealso [filter_trait_outliers()], [build_trait_table()]
#' @export
aggregate_trait_values <- function(
    data_trait_values,
    trait_value_column = "trait_value",
    group_columns = c("taxon_name", "trait_domain_name"),
    aggregation_method = c("median", "mean")) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_values),
    msg = "'data_trait_values' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(trait_value_column) &&
      base::length(trait_value_column) == 1L,
    msg = "'trait_value_column' must be a single character string."
  )

  assertthat::assert_that(
    trait_value_column %in% base::colnames(data_trait_values),
    msg = base::paste0(
      "'trait_value_column' column '", trait_value_column,
      "' not found in 'data_trait_values'."
    )
  )

  assertthat::assert_that(
    base::is.character(group_columns) &&
      base::length(group_columns) >= 1L,
    msg = "'group_columns' must be a character vector."
  )

  assertthat::assert_that(
    base::all(group_columns %in% base::colnames(data_trait_values)),
    msg = base::paste0(
      "All 'group_columns' must exist in 'data_trait_values'. Missing: ",
      base::paste(
        base::setdiff(
          group_columns,
          base::colnames(data_trait_values)
        ),
        collapse = ", "
      )
    )
  )

  aggregation_method <-
    base::match.arg(aggregation_method)

  aggregation_function <-
    if (aggregation_method == "median") {
      stats::median
    } else {
      base::mean
    }

  data_aggregated_trait_values <-
    data_trait_values |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(group_columns))
    ) |>
    dplyr::summarise(
      trait_value_aggregated = aggregation_function(
        .data[[trait_value_column]],
        na.rm = TRUE
      ),
      .groups = "drop"
    )

  return(data_aggregated_trait_values)
}

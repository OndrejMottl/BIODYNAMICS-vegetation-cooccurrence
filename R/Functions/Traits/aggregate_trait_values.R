#' @title Aggregate Trait Values to Single Value per Group
#' @description
#' Aggregates a long-format trait data frame to one row per group (by
#' default per taxon x trait combination) using a specified summary
#' function. Intended to be applied after outlier removal.
#' @param data
#' A data frame in long format with at least the columns specified by
#' `trait_col` and `group_cols`.
#' @param trait_col
#' A character string naming the numeric column containing trait values.
#' Default: `"trait_value"`.
#' @param group_cols
#' A character vector of column names used to define groups for
#' aggregation. Default: `c("taxon_name", "trait_domain_name")`.
#' @param fn
#' A character string specifying the aggregation function. One of
#' `"median"` (default) or `"mean"`. Matched with `match.arg()`.
#' @return
#' A data frame with one row per unique combination of `group_cols` and
#' a new column `trait_value_aggregated` containing the aggregated value.
#' @details
#' The `fn` argument is processed via `match.arg()`, so partial matching
#' is supported (e.g. `fn = "med"` resolves to `"median"`).
#' @seealso [filter_trait_outliers()], [make_trait_table()]
#' @export
aggregate_trait_values <- function(
    data,
    trait_col = "trait_value",
    group_cols = c("taxon_name", "trait_domain_name"),
    fn = c("median", "mean")) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame."
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
    base::is.character(group_cols) &&
      base::length(group_cols) >= 1L,
    msg = "'group_cols' must be a character vector."
  )

  assertthat::assert_that(
    base::all(group_cols %in% base::colnames(data)),
    msg = base::paste0(
      "All 'group_cols' must exist in 'data'. Missing: ",
      base::paste(
        base::setdiff(group_cols, base::colnames(data)),
        collapse = ", "
      )
    )
  )

  fn <-
    base::match.arg(fn)

  agg_fn <-
    if (fn == "median") {
      stats::median
    } else {
      base::mean
    }

  res <-
    data |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(group_cols))
    ) |>
    dplyr::summarise(
      trait_value_aggregated = agg_fn(
        .data[[trait_col]],
        na.rm = TRUE
      ),
      .groups = "drop"
    )

  return(res)
}

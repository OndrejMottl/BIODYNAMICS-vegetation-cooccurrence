#' @title Filter Trait Outliers Using IQR
#' @description
#' Removes outlier trait values from a long-format trait data frame using
#' the interquartile range (IQR) method. Outlier detection is performed
#' per group (by default per taxon x trait combination), mirroring the
#' fence logic used by boxplots: \[Q1 - k*IQR, Q3 + k*IQR\].
#' @param data
#' A data frame in long format with at least the columns specified by
#' `trait_col` and `group_cols`.
#' @param trait_col
#' A character string naming the numeric column containing trait values.
#' Default: `"trait_value"`.
#' @param group_cols
#' A character vector of column names used to define groups for outlier
#' detection. Default: `c("taxon_name", "trait_domain_name")`.
#' @param iqr_multiplier
#' A positive numeric scalar controlling the fence width, equivalent to
#' k in the standard boxplot formula. Default: `1.5`.
#' @return
#' A data frame with the same columns as the input but with outlier rows
#' removed. The number of removed rows is reported via
#' `cli::cli_inform()`.
#' @details
#' Groups with an IQR of zero (all values identical) are kept intact —
#' no filtering is applied to constant groups. This prevents inadvertent
#' removal of valid data when all observations share the same trait
#' value.
#' @seealso [aggregate_trait_values()]
#' @export
filter_trait_outliers <- function(
    data,
    trait_col = "trait_value",
    group_cols = c("taxon_name", "trait_domain_name"),
    iqr_multiplier = 1.5) {
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

  assertthat::assert_that(
    base::is.numeric(iqr_multiplier) &&
      base::length(iqr_multiplier) == 1L &&
      iqr_multiplier > 0,
    msg = paste0(
      "'iqr_multiplier' must be a single positive numeric."
    )
  )

  if (
    base::nrow(data) == 0L
  ) {
    return(data)
  }

  n_input <-
    base::nrow(data)

  # Pre-compute per-group fence bounds, then filter in a single,
  # readable step. Groups with IQR = 0 (all values identical) are kept
  # intact to avoid removing valid data when all observations agree.
  res <-
    data |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(group_cols))
    ) |>
    dplyr::mutate(
      .iqr = stats::IQR(.data[[trait_col]], na.rm = TRUE),
      .q1 = stats::quantile(.data[[trait_col]], probs = 0.25, na.rm = TRUE),
      .q3 = stats::quantile(.data[[trait_col]], probs = 0.75, na.rm = TRUE),
      .lower = .data[[".q1"]] - iqr_multiplier * .data[[".iqr"]],
      .upper = .data[[".q3"]] + iqr_multiplier * .data[[".iqr"]]
    ) |>
    dplyr::filter(
      .data[[".iqr"]] == 0 |
        (
          .data[[trait_col]] >= .data[[".lower"]] &
            .data[[trait_col]] <= .data[[".upper"]]
        )
    ) |>
    dplyr::select(-".iqr", -".q1", -".q3", -".lower", -".upper") |>
    dplyr::ungroup()

  n_removed <-
    n_input - base::nrow(res)

  cli::cli_inform(
    c(
      "i" = base::paste0(
        "Removed ", n_removed, " outlier row(s) from ",
        n_input, " total rows (",
        base::round(n_removed / n_input * 100, 1),
        "%)."
      )
    )
  )

  return(res)
}

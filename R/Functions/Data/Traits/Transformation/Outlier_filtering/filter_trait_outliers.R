#' @title Filter Trait Outliers Using IQR
#' @description
#' Removes outlier trait values from a long-format trait data frame using
#' the interquartile range (IQR) method. Outlier detection is performed
#' per group (by default per taxon x trait combination), mirroring the
#' fence logic used by boxplots: \[Q1 - k*IQR, Q3 + k*IQR\].
#' @param data_trait_records
#' A data frame in long format with at least the columns specified by
#' `trait_value_column` and `grouping_columns`.
#' @param trait_value_column
#' A character string naming the numeric column containing trait values.
#' Default: `"trait_value"`.
#' @param grouping_columns
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
#' @seealso [flag_trait_outliers()], [aggregate_trait_values()]
#' @export
filter_trait_outliers <- function(
    data_trait_records,
    trait_value_column = "trait_value",
    grouping_columns = c("taxon_name", "trait_domain_name"),
    iqr_multiplier = 1.5) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "'data_trait_records' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(trait_value_column) &&
      base::length(trait_value_column) == 1L,
    msg = "'trait_value_column' must be a single character string."
  )

  assertthat::assert_that(
    trait_value_column %in% base::colnames(data_trait_records),
    msg = base::paste0(
      "'trait_value_column' column '", trait_value_column,
      "' not found in 'data_trait_records'."
    )
  )

  assertthat::assert_that(
    base::is.character(grouping_columns) &&
      base::length(grouping_columns) >= 1L,
    msg = "'grouping_columns' must be a character vector."
  )

  assertthat::assert_that(
    base::all(
      grouping_columns %in% base::colnames(data_trait_records)
    ),
    msg = base::paste0(
      "All 'grouping_columns' must exist in 'data_trait_records'. ",
      "Missing: ",
      base::paste(
        base::setdiff(
          grouping_columns,
          base::colnames(data_trait_records)
        ),
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
    base::nrow(data_trait_records) == 0L
  ) {
    return(data_trait_records)
  }

  n_input_records <-
    base::nrow(data_trait_records)

  # Pre-compute per-group fence bounds, then filter in a single,
  # readable step. Groups with IQR = 0 (all values identical) are kept
  # intact to avoid removing valid data when all observations agree.
  data_filtered_trait_records <-
    data_trait_records |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(grouping_columns))
    ) |>
    dplyr::mutate(
      .iqr = stats::IQR(.data[[trait_value_column]], na.rm = TRUE),
      .q1 = stats::quantile(
        .data[[trait_value_column]],
        probs = 0.25,
        na.rm = TRUE
      ),
      .q3 = stats::quantile(
        .data[[trait_value_column]],
        probs = 0.75,
        na.rm = TRUE
      ),
      .lower = .data[[".q1"]] - iqr_multiplier * .data[[".iqr"]],
      .upper = .data[[".q3"]] + iqr_multiplier * .data[[".iqr"]]
    ) |>
    dplyr::filter(
      .data[[".iqr"]] == 0 |
        (
          .data[[trait_value_column]] >= .data[[".lower"]] &
            .data[[trait_value_column]] <= .data[[".upper"]]
        )
    ) |>
    dplyr::select(-".iqr", -".q1", -".q3", -".lower", -".upper") |>
    dplyr::ungroup()

  n_removed_records <-
    n_input_records - base::nrow(data_filtered_trait_records)

  cli::cli_inform(
    c(
      "i" = base::paste0(
        "Removed ", n_removed_records, " outlier row(s) from ",
        n_input_records, " total rows (",
        base::round(
          n_removed_records / n_input_records * 100,
          1
        ),
        "%)."
      )
    )
  )

  return(data_filtered_trait_records)
}

#' @title Flag Trait Outliers Within Groups
#' @description
#' Adds `n_group_records` and `is_trait_outlier` columns to grouped
#' trait records using a symmetric median-IQR fence. The caller is
#' responsible for grouping `data_trait_records` with
#' `dplyr::group_by()` before calling this function. The returned data
#' frame is always ungrouped.
#' @param data_trait_records
#' A grouped data frame (e.g. created by `dplyr::group_by()`).
#' Must contain the column named by `trait_value_column`.
#' @param trait_value_column
#' Character scalar. Name of the numeric column to test.
#' Default: `"trait_value"`.
#' @param iqr_multiplier
#' Positive numeric scalar. IQR fence multiplier. A value is
#' flagged when
#' `|value - group_median| > iqr_multiplier * group_IQR`.
#' @param minimum_group_size
#' Optional positive integer scalar. When supplied,
#' `is_trait_outlier` is set to `FALSE` for groups with fewer than
#' `minimum_group_size` records or with an IQR of zero. Default:
#' `NULL` (no group-size guard applied).
#' @return
#' An ungrouped data frame with the same rows and columns as
#' `data_trait_records` plus two additional columns:
#' \describe{
#'   \item{`n_group_records`}{Integer. Number of records in the group.}
#'   \item{`is_trait_outlier`}{Logical. `TRUE` when the record's
#'     value falls outside the IQR fence; `FALSE` otherwise.
#'     When `minimum_group_size` is supplied, also `FALSE` for groups
#'     that are too small or have zero IQR.}
#' }
#' @details
#' The IQR fence is
#' `[group_median - iqr_multiplier * group_IQR,
#'   group_median + iqr_multiplier * group_IQR]`.
#' Values outside this range receive `is_trait_outlier = TRUE`.
#'
#' When `minimum_group_size` is not `NULL`, an additional guard is
#' applied: groups with fewer than `minimum_group_size` records or a
#' `group_IQR` of zero always receive `is_trait_outlier = FALSE`.
#'
#' Designed for use in pipes where the caller sets up grouping:
#' ```r
#' data_traits |>
#'   dplyr::group_by(trait_domain_name) |>
#'   flag_trait_outliers(iqr_multiplier = 3)
#' ```
#' @seealso
#' [filter_trait_outliers()], [write_trait_quality_control_report()]
#' @export
flag_trait_outliers <- function(
    data_trait_records,
    trait_value_column = "trait_value",
    iqr_multiplier,
    minimum_group_size = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "'data_trait_records' must be a data frame."
  )

  assertthat::assert_that(
    base::length(dplyr::group_vars(data_trait_records)) > 0L,
    msg = stringr::str_c(
      "'data_trait_records' must be a grouped data frame. ",
      "Use dplyr::group_by() before calling this function."
    )
  )

  assertthat::assert_that(
    base::is.character(trait_value_column) &&
      base::length(trait_value_column) == 1L,
    msg = "'trait_value_column' must be a single character string."
  )

  assertthat::assert_that(
    trait_value_column %in% base::colnames(data_trait_records),
    msg = stringr::str_glue(
      "'trait_value_column' column '{trait_value_column}' not found ",
      "in 'data_trait_records'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(data_trait_records[[trait_value_column]]),
    msg = stringr::str_glue(
      "Column '{trait_value_column}' must be numeric."
    )
  )

  assertthat::assert_that(
    base::is.numeric(iqr_multiplier) &&
      base::length(iqr_multiplier) == 1L &&
      iqr_multiplier > 0,
    msg = "'iqr_multiplier' must be a single positive numeric."
  )

  if (
    !base::is.null(minimum_group_size)
  ) {
    assertthat::assert_that(
      base::is.numeric(minimum_group_size) &&
        base::length(minimum_group_size) == 1L &&
        minimum_group_size >= 1,
      msg = "'minimum_group_size' must be a single positive numeric."
    )
  }

  data_flagged_trait_records <-
    data_trait_records |>
    dplyr::mutate(
      n_group_records = dplyr::n(),
      group_median = stats::median(
        .data[[trait_value_column]],
        na.rm = TRUE
      ),
      group_iqr = stats::IQR(
        .data[[trait_value_column]],
        na.rm = TRUE
      ),
      is_trait_outlier = base::abs(
        .data[[trait_value_column]] - .data[["group_median"]]
      ) > iqr_multiplier * .data[["group_iqr"]]
    ) |>
    dplyr::ungroup()

  if (
    !base::is.null(minimum_group_size)
  ) {
    data_flagged_trait_records <-
      data_flagged_trait_records |>
      dplyr::mutate(
        is_trait_outlier =
          .data[["n_group_records"]] >= minimum_group_size &
          .data[["group_iqr"]] > 0 &
          .data[["is_trait_outlier"]]
      )
  }

  data_flagged_trait_records <-
    data_flagged_trait_records |>
    dplyr::mutate(
      n_group_records =
        base::as.integer(.data[["n_group_records"]])
    ) |>
    dplyr::select(
      -dplyr::all_of(base::c("group_median", "group_iqr"))
    )

  return(data_flagged_trait_records)
}

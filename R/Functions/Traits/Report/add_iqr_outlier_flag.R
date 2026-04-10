#' @title Add IQR Outlier Flag to a Grouped Data Frame
#' @description
#' Adds two columns — `n_group` and `is_outlier` — to a
#' pre-grouped data frame using a fence based on the
#' interquartile range (Tukey's method). The caller is
#' responsible for grouping `data` with `dplyr::group_by()`
#' before passing it to this function; the returned data frame
#' is always ungrouped.
#' @param data
#' A grouped data frame (e.g. created by `dplyr::group_by()`).
#' Must contain the column named by `col_value`.
#' @param col_value
#' Character scalar. Name of the numeric column to test.
#' Default: `"trait_value"`.
#' @param multiplier
#' Positive numeric scalar. IQR fence multiplier. A value is
#' flagged when
#' `|value - group_median| > multiplier * group_IQR`.
#' @param min_n
#' Optional positive integer scalar. When supplied,
#' `is_outlier` is set to `FALSE` for groups with fewer than
#' `min_n` records or with an IQR of zero (no meaningful
#' spread). Default: `NULL` (no group-size guard applied).
#' @return
#' An ungrouped data frame with the same rows and columns as
#' `data` plus two additional columns:
#' \describe{
#'   \item{`n_group`}{Integer. Number of records in the group.}
#'   \item{`is_outlier`}{Logical. `TRUE` when the record's
#'     value falls outside the IQR fence; `FALSE` otherwise.
#'     When `min_n` is supplied, also `FALSE` for groups that
#'     are too small or have zero IQR.}
#' }
#' @details
#' The IQR fence is
#' `[group_median - multiplier * group_IQR,
#'   group_median + multiplier * group_IQR]`.
#' Values outside this range receive `is_outlier = TRUE`.
#'
#' When `min_n` is not `NULL`, an additional guard is applied:
#' groups with fewer than `min_n` records or a `group_IQR` of
#' zero always receive `is_outlier = FALSE`.
#'
#' Designed for use in pipes where the caller sets up grouping:
#' ```r
#' data_traits |>
#'   dplyr::group_by(trait_domain_name) |>
#'   add_iqr_outlier_flag(multiplier = 3)
#' ```
#' @seealso
#' [filter_trait_outliers()], [generate_trait_qc_report()]
#' @export
add_iqr_outlier_flag <- function(
    data,
    col_value = "trait_value",
    multiplier,
    min_n = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame."
  )

  assertthat::assert_that(
    base::length(dplyr::group_vars(data)) > 0L,
    msg = base::paste0(
      "'data' must be a grouped data frame. ",
      "Use dplyr::group_by() before calling this function."
    )
  )

  assertthat::assert_that(
    base::is.character(col_value) &&
      base::length(col_value) == 1L,
    msg = "'col_value' must be a single character string."
  )

  assertthat::assert_that(
    col_value %in% base::colnames(data),
    msg = base::paste0(
      "'col_value' column '", col_value,
      "' not found in 'data'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(data[[col_value]]),
    msg = base::paste0(
      "Column '", col_value, "' must be numeric."
    )
  )

  assertthat::assert_that(
    base::is.numeric(multiplier) &&
      base::length(multiplier) == 1L &&
      multiplier > 0,
    msg = base::paste0(
      "'multiplier' must be a single positive numeric."
    )
  )

  if (
    !base::is.null(min_n)
  ) {
    assertthat::assert_that(
      base::is.numeric(min_n) &&
        base::length(min_n) == 1L &&
        min_n >= 1,
      msg = base::paste0(
        "'min_n' must be a single positive numeric."
      )
    )
  }

  res_data <-
    data |>
    dplyr::mutate(
      n_group = dplyr::n(),
      group_median = stats::median(
        .data[[col_value]],
        na.rm = TRUE
      ),
      group_iqr = stats::IQR(
        .data[[col_value]],
        na.rm = TRUE
      ),
      is_outlier = base::abs(
        .data[[col_value]] - .data[["group_median"]]
      ) > multiplier * .data[["group_iqr"]]
    ) |>
    dplyr::ungroup()

  if (
    !base::is.null(min_n)
  ) {
    res_data <-
      res_data |>
      dplyr::mutate(
        is_outlier = .data[["n_group"]] >= min_n &
          .data[["group_iqr"]] > 0 &
          .data[["is_outlier"]]
      )
  }

  res_data <-
    res_data |>
    dplyr::mutate(
      n_group = base::as.integer(.data[["n_group"]])
    ) |>
    dplyr::select(
      -dplyr::all_of(base::c("group_median", "group_iqr"))
    )

  return(res_data)
}

#' @title Validate Sample Count
#' @description
#' Guards against running downstream data preparation and model
#' fitting on a time slice with too few
#' `(dataset_name, age)` combinations. Returns
#' `data_sample_ids` unchanged when the row count is at least
#' `minimum_sample_count`. Stops with an informative error when the
#' count falls below the threshold, preventing expensive model
#' fitting on near-empty slices.
#' @param data_sample_ids
#' A data frame with at least the columns `dataset_name` and
#' `age`, as returned by `align_sample_ids()`. Each row
#' represents one valid `(dataset_name, age)` pair.
#' @param minimum_sample_count
#' A single positive integer giving the minimum number of
#' samples (rows) required to proceed with data preparation
#' and model fitting. Default is 1.
#' @return
#' The input `data_sample_ids` unchanged, when
#' `nrow(data_sample_ids) >= minimum_sample_count`.
#' @details
#' The check counts `nrow(data_sample_ids)` after the
#' time-slice filter has been applied by
#' `align_sample_ids(subset_age = ...)`. If the count falls
#' below `minimum_sample_count`, `cli::cli_abort()` is called with a
#' message that reports the actual sample count and the
#' threshold, allowing the user to adjust the configuration or
#' the input data. This check is intended to be placed in the
#' per-slice pipeline (e.g. `pipe_segment_sample_filter_age`) so
#' that slices without sufficient data fail immediately,
#' before any expensive preparation or model fitting.
#' @seealso [align_sample_ids()],
#'   [validate_community_taxon_count()]
#' @export
validate_sample_count <- function(
    data_sample_ids = NULL,
    minimum_sample_count = 1) {
  assertthat::assert_that(
    base::is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "age") %in%
        base::names(data_sample_ids)
    ),
    msg = stringr::str_c(
      "data_sample_ids must contain columns ",
      "'dataset_name' and 'age'"
    )
  )

  assertthat::assert_that(
    base::is.numeric(minimum_sample_count) &&
      base::length(minimum_sample_count) == 1L,
    msg = "minimum_sample_count must be a numeric scalar"
  )

  assertthat::assert_that(
    minimum_sample_count >= 1,
    msg = "minimum_sample_count must be greater than or equal to 1"
  )

  sample_count <-
    base::nrow(data_sample_ids)

  if (
    sample_count < minimum_sample_count
  ) {
    cli::cli_abort(
      base::c(
        stringr::str_c(
          "Too few samples in this time slice to proceed",
          " with data preparation and model fitting."
        ),
        "i" = stringr::str_c(
          "Found {sample_count} sample(s) but at least",
          " {minimum_sample_count} are required."
        ),
        "i" = stringr::str_c(
          "Adjust the minimum sample count in the configuration",
          " or review the input data for this age slice."
        )
      )
    )
  }

  return(data_sample_ids)
}

#' @title Check Sample IDs Have Minimum Number of Samples
#' @description
#' Guards against running downstream data preparation and model
#' fitting on a time slice with too few
#' `(dataset_name, age)` combinations. Returns
#' `data_sample_ids` unchanged when the row count is at least
#' `min_n_samples`. Stops with an informative error when the
#' count falls below the threshold, preventing expensive model
#' fitting on near-empty slices.
#' @param data_sample_ids
#' A data frame with at least the columns `dataset_name` and
#' `age`, as returned by `align_sample_ids()`. Each row
#' represents one valid `(dataset_name, age)` pair.
#' @param min_n_samples
#' A single positive integer giving the minimum number of
#' samples (rows) required to proceed with data preparation
#' and model fitting. Default is 1.
#' @return
#' The input `data_sample_ids` unchanged, when
#' `nrow(data_sample_ids) >= min_n_samples`.
#' @details
#' The check counts `nrow(data_sample_ids)` after the
#' time-slice filter has been applied by
#' `align_sample_ids(subset_age = ...)`. If the count falls
#' below `min_n_samples`, `cli::cli_abort()` is called with a
#' message that reports the actual sample count and the
#' threshold, allowing the user to adjust the configuration or
#' the input data. This check is intended to be placed in the
#' per-slice pipeline (e.g. `pipe_segment_age_filter`) so
#' that slices without sufficient data fail immediately,
#' before any expensive preparation or model fitting.
#' @seealso [align_sample_ids()],
#'   [filter_community_by_n_taxa()]
#' @export
check_data_sample_ids_n <- function(
    data_sample_ids = NULL,
    min_n_samples = 1) {
  assertthat::assert_that(
    is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "age") %in% names(data_sample_ids)),
    msg = paste0(
      "data_sample_ids must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  assertthat::assert_that(
    is.numeric(min_n_samples) &&
      length(min_n_samples) == 1,
    msg = "min_n_samples must be a single numeric value"
  )

  assertthat::assert_that(
    min_n_samples >= 1,
    msg = "min_n_samples must be greater than or equal to 1"
  )

  n_samples <-
    nrow(data_sample_ids)

  if (n_samples < min_n_samples) {
    cli::cli_abort(
      c(
        paste0(
          "Too few samples in this time slice to proceed",
          " with data preparation and model fitting."
        ),
        "i" = paste0(
          "Found {n_samples} sample(s) but at least",
          " {min_n_samples} are required."
        ),
        "i" = paste0(
          "Adjust `min_n_samples` in the configuration",
          " or review the input data for this age slice."
        )
      )
    )
  }

  return(data_sample_ids)
}

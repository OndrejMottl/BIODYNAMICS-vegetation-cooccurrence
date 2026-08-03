#' @title Validate Available Core Count
#' @description
#' Verifies that the number of cores (distinct pollen sites) in the
#' current spatial window meets the minimum required for analysis.
#' The check is intended as an early guard in the pipeline, applied
#' directly to `data_coords` (output of `get_coords()`) before any
#' expensive community-data processing begins.
#' @param data_coords
#' A data frame of site coordinates, one row per core, as returned by
#' `get_coords()`. Gridpoints are already excluded by that function, so
#' every row represents a real pollen core.
#' @param minimum_core_count
#' A single positive numeric value specifying the minimum number of
#' distinct cores required. Typically sourced from
#' the configured minimum core-count threshold.
#' @return
#' `TRUE` invisibly when the check passes.
#' @details
#' Raises a `cli::cli_abort()` error naming the actual core count and
#' the required threshold when `nrow(data_coords) < minimum_core_count`. This
#' causes the targets pipeline target to fail immediately, preventing
#' all downstream community-data targets from running for spatial windows
#' that contain too few sites.
#' @seealso [get_coords()], [filter_community_by_minimum_core_count()]
#' @export
validate_available_core_count <- function(
    data_coords = NULL,
    minimum_core_count = 2) {
  assertthat::assert_that(
    base::is.data.frame(data_coords),
    msg = "'data_coords' must be a data frame"
  )

  assertthat::assert_that(
    base::is.numeric(minimum_core_count) &&
      base::length(minimum_core_count) == 1L,
    msg = "minimum_core_count must be a numeric scalar"
  )

  assertthat::assert_that(
    minimum_core_count >= 1,
    msg = "'minimum_core_count' must be greater than or equal to 1"
  )

  available_core_count <-
    base::nrow(data_coords)

  if (
    available_core_count < minimum_core_count
  ) {
    cli::cli_abort(
      base::c(
        "Not enough cores in this spatial window.",
        "i" = stringr::str_c(
          "Found {available_core_count} core(s); at least ",
          "{minimum_core_count} required."
        ),
        "i" = stringr::str_c(
          "Adjust the minimum core count in the configuration or choose a",
          " larger spatial window."
        )
      )
    )
  }

  return(base::invisible(TRUE))
}

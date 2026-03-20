#' @title Check Minimum Number of Cores in Spatial Window
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
#' @param min_n_cores
#' A single positive numeric value specifying the minimum number of
#' distinct cores required. Typically sourced from
#' `config.data_processing$min_n_cores`.
#' @return
#' `TRUE` invisibly when the check passes.
#' @details
#' Raises a `cli::cli_abort()` error naming the actual core count and
#' the required threshold when `nrow(data_coords) < min_n_cores`. This
#' causes the targets pipeline target to fail immediately, preventing
#' all downstream community-data targets from running for spatial windows
#' that contain too few sites.
#' @seealso [get_coords()], [filter_community_by_n_cores()]
#' @export
check_min_n_cores <- function(
    data_coords = NULL,
    min_n_cores = 2) {
  assertthat::assert_that(
    base::is.data.frame(data_coords),
    msg = "'data_coords' must be a data frame"
  )

  assertthat::assert_that(
    base::is.numeric(min_n_cores) &&
      base::length(min_n_cores) == 1,
    msg = "'min_n_cores' must be a single numeric value"
  )

  assertthat::assert_that(
    min_n_cores >= 1,
    msg = "'min_n_cores' must be greater than or equal to 1"
  )

  n_cores_available <- base::nrow(data_coords)

  if (n_cores_available < min_n_cores) {
    cli::cli_abort(
      c(
        "Not enough cores in this spatial window.",
        "i" = base::paste0(
          "Found ", n_cores_available,
          " core(s); at least ", min_n_cores, " required."
        ),
        "i" = paste0(
          "Adjust 'min_n_cores' in config or choose a",
          " larger spatial window."
        )
      )
    )
  }

  return(invisible(TRUE))
}

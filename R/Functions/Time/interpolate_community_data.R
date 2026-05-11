#' @title Interpolate Community Data
#' @description
#' Interpolates community proportion data to a regular time grid.
#' @param data
#' A data frame with columns `dataset_name`, `taxon`, `age`, and
#' `value`. Must already be in proportion form — see
#' [make_community_proportions()].
#' @param n_cores
#' Number of cores to use for interpolation. Passed to
#' [interpolate_data()].
#' @param ...
#' Additional arguments passed to [interpolate_data()], such as
#' `timestep`, `age_min`, and `age_max`.
#' @return
#' A data frame with interpolated community data at regular time
#' intervals.
#' @details
#' Calls [interpolate_data()] grouped by `dataset_name` and `taxon`.
#' Data must be converted to proportions before calling this function
#' using [make_community_proportions()].
#' @seealso [make_community_proportions()], [interpolate_data()]
#' @export
interpolate_community_data <- function(data, n_cores = 1, ...) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    "value" %in% base::colnames(data),
    msg = stringr::str_c(
      "data must contain a 'value' column.",
      "Use make_community_proportions() first.",
      sep = " "
    )
  )

  res <-
      data |>
    interpolate_data(
      by = base::c("dataset_name", "taxon"),
      n_cores = n_cores,
      ...
    )

  base::return(res)
}

#' @title Interpolate Community Data
#' @description
#' Interpolates community proportion data to a regular time grid.
#' @param data
#' A data frame with columns `dataset_name`, `taxon`, `age`, and
#' `value`. Must already be in proportion form — see
#' [make_community_proportions()].
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
interpolate_community_data <- function(data, ...) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    "value" %in% colnames(data),
    msg = paste(
      "data must contain a 'value' column.",
      "Use make_community_proportions() first."
    )
  )

  res <-
    data %>%
    interpolate_data(
      by = c("dataset_name", "taxon"),
      ...
    )

  return(res)
}

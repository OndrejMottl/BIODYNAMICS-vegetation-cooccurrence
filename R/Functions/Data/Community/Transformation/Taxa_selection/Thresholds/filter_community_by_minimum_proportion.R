#' @title Filter Community by Minimum Proportion
#' @description
#' Retains community records whose value meets a minimum proportion threshold.
#' @param data_community
#' A data frame containing taxon abundance data. Must include a column
#' named 'value' with numeric proportions or abundances.
#' @param minimum_proportion
#' Numeric value between 0 and 1 specifying the minimum proportion
#' threshold for retaining taxa. Default is 0.01 (one percent).
#' @return
#' A filtered data frame containing only taxa that meet or exceed the
#' minimum proportion threshold. Preserves all original columns.
#' @details
#' The function validates that `minimum_proportion` is a numeric value
#' between 0 and 1. After filtering, it checks that at least one taxon
#' remains in the dataset. If no taxa meet the threshold, an error is
#' raised suggesting the threshold may be too high.
#' @export
filter_community_by_minimum_proportion <- function(
    data_community = NULL,
    minimum_proportion = 0.01) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    base::is.numeric(minimum_proportion) &&
      base::length(minimum_proportion) == 1L,
    msg = "minimum_proportion must be a numeric scalar"
  )

  assertthat::assert_that(
    minimum_proportion > 0,
    msg = "minimum_proportion must be greater than 0"
  )

  assertthat::assert_that(
    minimum_proportion <= 1,
    msg = "minimum_proportion must be less than or equal to 1"
  )

  res_community_filtered <-
    data_community |>
    dplyr::filter(value >= minimum_proportion)

  assertthat::assert_that(
    base::nrow(res_community_filtered) > 0L,
    msg = stringr::str_c(
      "No taxa found in data. Please check the input data. ",
      "The minimum_proportion is too high."
    )
  )

  return(res_community_filtered)
}

#' @title Filter Rare Taxa
#' @description
#' Filters out rare taxa from community data based on a minimum proportion
#' threshold. Only taxa meeting or exceeding the threshold are retained.
#' @param data
#' A data frame containing taxon abundance data. Must include a column
#' named 'pollen_prop' with numeric proportions or abundances.
#' @param minimal_proportion
#' Numeric value between 0 and 1 specifying the minimum proportion
#' threshold for retaining taxa. Default is 0.01 (1%).
#' @return
#' A filtered data frame containing only taxa that meet or exceed the
#' minimal proportion threshold. Preserves all original columns.
#' @details
#' The function validates that minimal_proportion is a numeric value
#' between 0 and 1. After filtering, it checks that at least one taxon
#' remains in the dataset. If no taxa meet the threshold, an error is
#' raised suggesting the threshold may be too high.
#' @export
filter_rare_taxa <- function(
    data = NULL,
    minimal_proportion = 0.01) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    is.numeric(minimal_proportion),
    msg = "minimal_proportion must be a number"
  )

  assertthat::assert_that(
    minimal_proportion > 0,
    msg = "minimal_proportion must be greater than 0"
  )

  assertthat::assert_that(
    minimal_proportion <= 1,
    msg = "minimal_proportion must be less than or equal to 1"
  )

  res <-
    data |>
    dplyr::filter(pollen_prop >= minimal_proportion)


  assertthat::assert_that(
    nrow(res) > 0,
    msg = paste(
      "No taxa found in data. Please check the input data.",
      "The minimal_proportion is too high."
    )
  )

  return(res)
}

#' @title Get Community Data
#' @description
#' Processes a data frame containing community data and extracts the relevant
#' columns, unnesting the `data_community` column in the process.
#' @param data
#' A data frame. Must contain the columns `dataset_name` and
#' `data_community`.
#' @return
#' A data frame with the `dataset_name` and unnested `data_community` columns.
#' @details
#' Validates that the input is a data frame, ensures the presence of the
#' `dataset_name` and `data_community` columns, selects those columns, and
#' unnests the `data_community` column.
#' @export
get_community_data <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "data_community") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'data_community'"
  )

  data %>%
    dplyr::select(dataset_name, data_community) %>%
    tidyr::unnest(data_community) %>%
    return()
}

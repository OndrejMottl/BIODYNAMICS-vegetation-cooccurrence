#' @title Interpolate Community Data
#' @description
#' Transforms community data to proportions, interpolates it, and returns it.
#' @param data
#' A data frame containing community data to be transformed and interpolated.
#' @param ...
#' Additional arguments passed to the `interpolate_data` function.
#' @return
#' A data frame with interpolated community data.
#' @details
#' Transforms data to proportions using `transform_to_proportions` and total
#' pollen count from `get_pollen_sum`. Then interpolates using `interpolate_data`.
#' @export
interpolate_community_data <- function(data, ...) {
  data %>%
    transform_to_proportions(pollen_sum = get_pollen_sum(data)) %>%
    interpolate_data(by = c("dataset_name", "taxon"), ...) %>%
    return()
}

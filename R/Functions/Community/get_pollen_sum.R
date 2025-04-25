#' @title Calculate the Total Pollen Count for Each Sample
#' @description
#' This function computes the total pollen count for each sample
#' in the provided dataset.
#' @param data
#' A data frame containing at least two columns:
#' `sample_name` (the name or identifier of the sample)
#' and `pollen_count` (the count of pollen for each observation).
#' @return
#' A data frame with two columns: `sample_name` and `pollen_sum`,
#' where `pollen_sum` is the total pollen count
#' for each sample.
#' @details
#' The function groups the data by `sample_name`,
#' calculates the sum of `pollen_count` for each group,
#' and removes any grouping structure before returning the result.
#' Missing values (`NA`) in `pollen_count` are ignored.
#' @export
get_pollen_sum <- function(data) {
  data %>%
    dplyr::group_by(sample_name) %>%
    dplyr::summarize(pollen_sum = sum(pollen_count, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    return()
}

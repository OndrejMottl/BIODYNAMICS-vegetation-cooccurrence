#' @title Transform to Proportions
#' @description
#' Transforms pollen count data into proportions based on total pollen count.
#' @param data
#' A data frame containing pollen count data.
#' @param pollen_sum
#' A data frame with total pollen counts for each sample.
#' @return
#' A data frame with pollen proportions, excluding `pollen_sum` and
#' `pollen_count` columns.
#' @details
#' Joins the input data with total pollen counts and calculates proportions
#' using `dplyr::mutate`.
#' @export
transform_to_proportions <- function(data = NULL, pollen_sum = NULL) {
  data %>%
    dplyr::left_join(
      pollen_sum,
      by = "sample_name"
    ) %>%
    dplyr::mutate(
      pollen_prop = pollen_count / pollen_sum,
      .after = pollen_count
    ) %>%
    dplyr::select(
      !c("pollen_sum", "pollen_count")
    ) %>%
    return()
}

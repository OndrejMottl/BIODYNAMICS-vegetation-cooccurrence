#' @title Make Community Data Long
#' @description
#' Converts community data from wide format to long format.
#' @param data
#' A data frame. Must contain `dataset_name` and `sample_name` columns.
#' @return
#' A data frame in long format with columns `dataset_name`, `sample_name`,
#' `taxon`, and `pollen_count`.
#' @details
#' Uses `tidyr::pivot_longer` to reshape the data, dropping NA values in the
#' process.
#' @export
make_community_data_long <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "sample_name") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'sample_name'"
  )

  data %>%
    tidyr::pivot_longer(
      cols = !c("dataset_name", "sample_name"),
      names_to = "taxon",
      values_to = "pollen_count",
      values_drop_na = TRUE
    ) %>%
    return()
}

#' @title Add Age to Community Data
#' @description
#' Merges community data with age data based on dataset and sample names.
#' @param data_community
#' A data frame containing community data. Must include `dataset_name` and
#' `sample_name` columns.
#' @param data_ages
#' A data frame containing age data. Must include `dataset_name` and
#' `sample_name` columns.
#' @return
#' A data frame with community data merged with the corresponding age data.
#' @details
#' Performs a left join between community data and age data using
#' `dataset_name` and `sample_name` as keys.
#' @export
add_age_to_samples <- function(data_community = NULL, data_ages = NULL) {
  assertthat::assert_that(
    is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )
  assertthat::assert_that(
    is.data.frame(data_ages),
    msg = "data_ages must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "sample_name") %in% colnames(data_community)),
    msg = "data_community must contain columns 'dataset_name' and 'sample_name'"
  )
  assertthat::assert_that(
    all(c("dataset_name", "sample_name") %in% colnames(data_ages)),
    msg = "data_ages must contain columns 'dataset_name' and 'sample_name'"
  )

  dplyr::left_join(
    x = data_community,
    y = data_ages,
    by = c("dataset_name", "sample_name")
  ) %>%
    return()
}

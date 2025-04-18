add_age_to_community_data <- function(data_community = NULL, data_ages = NULL) {
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

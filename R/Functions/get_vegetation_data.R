get_vegetation_data <- function(data = NULL) {
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

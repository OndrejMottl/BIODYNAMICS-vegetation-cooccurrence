get_sample_ages <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "data_samples") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'data_samples'"
  )

  data %>%
    dplyr::select(dataset_name, data_samples) %>%
    tidyr::unnest(data_samples) %>%
    dplyr::select(
      "dataset_name",
      "sample_name",
      "age"
    ) %>%
    return()
}

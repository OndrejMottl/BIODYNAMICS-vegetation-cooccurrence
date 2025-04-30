get_abiotic_data <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "data_abiotic") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'data_abiotic'"
  )
  data %>%
    dplyr::select(dataset_name, data_abiotic) %>%
    tidyr::unnest(
      cols = c(data_abiotic)
    ) %>%
    dplyr::select(dataset_name, sample_name, abiotic_variable_name, abiotic_value) %>%
    return()
}

#' @title Extract Abiotic Data
#' @description
#' Extracts abiotic data from a data frame containing nested abiotic
#' information.
#' @param data_source
#' A data frame. Must contain the columns `dataset_name` and `data_abiotic`.
#' @return
#' A data frame with columns `dataset_name`, `sample_name`,
#' `abiotic_variable_name`, and `abiotic_value`.
#' @details
#' Validates the input data frame, ensures required columns are present, and
#' unnests the `data_abiotic` column.
#' @export
extract_abiotic_data <- function(data_source = NULL) {
  assertthat::assert_that(
    is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("dataset_name", "data_abiotic") %in%
        colnames(data_source)
    ),
    msg = "data_source must contain columns 'dataset_name' and 'data_abiotic'"
  )
  data_source %>%
    dplyr::select(dataset_name, data_abiotic) %>%
    tidyr::unnest(
      cols = c(data_abiotic)
    ) %>%
    dplyr::select(
      dataset_name,
      sample_name,
      abiotic_variable_name,
      abiotic_value
    ) %>%
    return()
}

#' @title Add Dataset Name Column from Row Names
#' @description
#' Adds a 'dataset_name' column to a data frame by extracting dataset names
#' from row names.
#' @param data
#' A data frame with row names in the format "dataset__something".
#' @return
#' The input data frame with an added 'dataset_name' column.
#' @export
prepare_dataset_name_column_from_rownames <- function(data) {
  row_names <-
    row.names(data) %>%
    extract_dataset_name_from_sample_names()

  data %>%
    dplyr::mutate(
      dataset_name = row_names
    ) %>%
    return()
}

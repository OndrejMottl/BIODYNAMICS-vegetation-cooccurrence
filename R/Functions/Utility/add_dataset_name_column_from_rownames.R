add_dataset_name_column_from_rownames <- function(data) {
  row_names <-
    row.names(data) %>%
    get_dataset_name_from_string()

  data %>%
    dplyr::mutate(
      dataset_name = row_names
    ) %>%
    return()
}

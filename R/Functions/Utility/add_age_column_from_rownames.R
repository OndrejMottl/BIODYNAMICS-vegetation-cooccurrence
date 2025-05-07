add_age_column_from_rownames <- function(data) {
  row_names <-
    row.names(data) %>%
    get_age_from_string()

  data %>%
    dplyr::mutate(
      age = row_names
    ) %>%
    return()
}

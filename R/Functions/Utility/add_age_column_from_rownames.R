#' @title Add Age Column from Row Names
#' @description
#' Adds an 'age' column to a data frame by extracting age values from row
#' names.
#' @param data
#' A data frame with row names in the format "dataset__age".
#' @return
#' The input data frame with an added 'age' column.
#' @export
add_age_column_from_rownames <- function(data) {
  row_names <-
    row.names(data) %>%
    get_age_from_string()

  data %>%
    dplyr::mutate(
      age = as.numeric(row_names)
    ) %>%
    return()
}

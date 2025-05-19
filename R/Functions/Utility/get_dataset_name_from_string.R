#' @title Extract Dataset Name from String
#' @description
#' Extracts the dataset name from a vector of strings, taking all characters
#' before the double underscore ("__").
#' @param vec_names
#' A character vector containing names with the format "dataset__something".
#' @return
#' A character vector of dataset names.
#' @export
get_dataset_name_from_string <- function(vec_names) {
  vec_names %>%
    # get all values before double "__"
    stringr::str_extract(".*(?=__)") %>%
    stringr::str_trim() %>%
    return()
}

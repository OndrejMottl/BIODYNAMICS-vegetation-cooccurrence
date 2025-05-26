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
  assertthat::assert_that(
    is.character(vec_names),
    msg = "Input must be a character vector."
  )

  assertthat::assert_that(
    length(vec_names) > 0,
    msg = "Input vector must not be empty."
  )

  assertthat::assert_that(
    all(stringr::str_detect(vec_names, "__")),
    msg = "Input strings must contain '__' to extract dataset names."
  )

  vec_names %>%
    # get all values before double "__"
    stringr::str_extract(".*(?=__)") %>%
    stringr::str_trim() %>%
    return()
}

#' @title Extract Age from String
#' @description
#' Extracts the age value from a vector of strings, taking all characters
#' after the double underscore ("__").
#' @param vec_names
#' A character vector containing names with the format "dataset__age".
#' @return
#' A character vector of age values.
#' @export
get_age_from_string <- function(vec_names) {
  vec_names %>%
    # get all values after "__"
    stringr::str_extract("__(.*)") %>%
    # remove "__"
    stringr::str_remove("__") %>%
    stringr::str_trim() %>%
    return()
}

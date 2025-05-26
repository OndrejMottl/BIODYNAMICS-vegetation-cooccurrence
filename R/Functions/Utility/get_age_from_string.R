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
    msg = "Input strings must contain '__' to extract age."
  )

  vec_names %>%
    # get all values after "__"
    stringr::str_extract("__(.*)") %>%
    # remove "__"
    stringr::str_remove("__") %>%
    stringr::str_trim() %>%
    return()
}

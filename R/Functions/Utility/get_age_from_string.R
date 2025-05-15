get_age_from_string <- function(vec_names) {
  vec_names %>%
    # get all values after "__"
    stringr::str_extract("__(.*)") %>%
    # remove "__"
    stringr::str_remove("__") %>%
    stringr::str_trim() %>%
    return()
}

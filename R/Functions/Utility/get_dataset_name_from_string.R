get_dataset_name_from_string <- function(vec_names) {
  vec_names %>%
    # get all values before double "__"
    stringr::str_extract(".*(?=__)") %>%
    stringr::str_trim() %>%
    return()
}

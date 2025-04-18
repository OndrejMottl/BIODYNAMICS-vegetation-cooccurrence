get_pollen_sum <- function(data) {
  data %>%
    dplyr::group_by(sample_name) %>%
    dplyr::summarize(pollen_sum = sum(pollen_count, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    return()
}

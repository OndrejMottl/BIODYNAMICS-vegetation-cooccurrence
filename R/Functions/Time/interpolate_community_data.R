interpolate_community_data <- function(data, ...) {
  data %>%
    transform_to_proportions(pollen_sum = get_pollen_sum(data)) %>%
    interpolate_data(...) %>%
    return()
}

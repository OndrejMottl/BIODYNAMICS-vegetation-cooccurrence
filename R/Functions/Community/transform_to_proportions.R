transform_to_proportions <- function(data = NULL, pollen_sum = NULL) {
  data %>%
    dplyr::left_join(
      pollen_sum,
      by = "sample_name"
    ) %>%
    dplyr::mutate(
      pollen_prop = pollen_count / pollen_sum,
      .after = pollen_count
    ) %>%
    dplyr::select(
      !c("pollen_sum", "pollen_count")
    ) %>%
    return()
}

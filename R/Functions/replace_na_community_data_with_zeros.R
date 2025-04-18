replace_na_community_data_with_zeros <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )
  assertthat::assert_that(
    all(c("dataset_name", "sample_name") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'sample_name'"
  )

  assertthat::assert_that(
    colnames(data) %>%
      length() > 2,
    msg = "data must contain at least one taxon column"
  )

  data %>%
    tidyr::pivot_longer(
      cols = !c("dataset_name", "sample_name"),
      names_to = "taxon",
      values_to = "pollen_count"
    ) %>%
    dplyr::mutate(
      pollen_count = dplyr::if_else(is.na(pollen_count), 0, pollen_count)
    ) %>%
    tidyr::pivot_wider(
      names_from = "taxon",
      values_from = "pollen_count"
    ) %>%
    return()
}

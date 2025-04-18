make_community_data_long <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "sample_name") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'sample_name'"
  )

  data %>%
    tidyr::pivot_longer(
      cols = !c("dataset_name", "sample_name"),
      names_to = "taxon",
      values_to = "pollen_count",
      values_drop_na = TRUE
    ) %>%
    return()
}
